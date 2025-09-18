#!/bin/bash
# Cross-repo compatibility testing script
# Usage: ./scripts/compatibility-test.sh [hyku_ref] [test_suite]

set -e

# Configuration
HYKU_REF=${1:-"main"}
TEST_SUITE=${2:-"core"}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Cleanup function
cleanup() {
    log_info "Cleaning up..."
    cd "$PROJECT_ROOT"
    docker-compose down -v >/dev/null 2>&1 || true
    docker system prune -f >/dev/null 2>&1 || true
}

# Set up cleanup trap
trap cleanup EXIT

main() {
    cd "$PROJECT_ROOT"
    
    log_info "Starting cross-repo compatibility test"
    log_info "Hyku ref: $HYKU_REF"
    log_info "Test suite: $TEST_SUITE"
    echo
    
    # Verify environment files exist
    if [[ ! -f .env ]]; then
        if [[ -f .env.sample ]]; then
            log_info "Creating .env from sample"
            cp .env.sample .env
        else
            log_error ".env file not found and no sample available"
            exit 1
        fi
    fi
    
    if [[ ! -f .env.development ]]; then
        if [[ -f .env.development.sample ]]; then
            log_info "Creating .env.development from sample"
            cp .env.development.sample .env.development
        else
            log_warning ".env.development not found, creating minimal version"
            touch .env.development
        fi
    fi
    
    # Ensure knapsack bundle settings
    if ! grep -q "BUNDLE_LOCAL__HYKU_KNAPSACK" .env.development; then
        echo "BUNDLE_LOCAL__HYKU_KNAPSACK=/app/samvera" >> .env.development
    fi
    if ! grep -q "BUNDLE_DISABLE_LOCAL_BRANCH_CHECK" .env.development; then
        echo "BUNDLE_DISABLE_LOCAL_BRANCH_CHECK=true" >> .env.development
    fi
    
    # Setup Hyku submodule
    log_info "Setting up Hyku submodule with ref: $HYKU_REF"
    git submodule init
    
    cd hyrax-webapp
    git fetch origin "$HYKU_REF"
    git checkout "$HYKU_REF"
    HYKU_SHA=$(git rev-parse HEAD)
    log_success "Checked out Hyku at SHA: $HYKU_SHA"
    
    # Update knapsack reference in Hyku Gemfile
    log_info "Updating knapsack reference in Hyku Gemfile"
    KNAPSACK_SHA=$(cd .. && git rev-parse HEAD)
    
    if grep -q "github: 'samvera-labs/hyku_knapsack'" Gemfile; then
        sed -i.bak "s|github: 'samvera-labs/hyku_knapsack'.*|github: 'samvera-labs/hyku_knapsack', ref: '$KNAPSACK_SHA'|" Gemfile
        log_success "Updated knapsack reference to SHA: $KNAPSACK_SHA"
    else
        log_warning "Could not find knapsack gem reference in Gemfile"
    fi
    
    cd ..
    
    # Build Docker images
    log_info "Building Docker images..."
    if ! docker-compose build web; then
        log_error "Failed to build Docker images"
        exit 1
    fi
    log_success "Docker images built successfully"
    
    # Start services
    log_info "Starting services..."
    docker-compose up -d db redis solr fcrepo
    
    # Wait for services to be ready
    log_info "Waiting for services to be ready..."
    sleep 10
    
    # Setup database
    log_info "Setting up database..."
    if ! docker-compose run --rm web bash -c "
        cd /app/samvera/hyrax-webapp && 
        bundle exec rails db:create db:migrate db:seed
    "; then
        log_error "Database setup failed"
        exit 1
    fi
    log_success "Database setup completed"
    
    # Test knapsack loading
    log_info "Testing knapsack loading..."
    if ! docker-compose run --rm web bash -c "
        cd /app/samvera/hyrax-webapp &&
        bundle exec rails runner 'puts \"HykuKnapsack version: #{HykuKnapsack::VERSION}\"'
    "; then
        log_error "Knapsack loading test failed"
        exit 1
    fi
    log_success "Knapsack loaded successfully"
    
    # Run test suite based on selection
    case "$TEST_SUITE" in
        "core")
            run_core_tests
            ;;
        "integration")
            run_integration_tests
            ;;
        "full")
            run_full_tests
            ;;
        "smoke")
            run_smoke_tests
            ;;
        *)
            log_error "Unknown test suite: $TEST_SUITE"
            log_info "Available options: core, integration, full, smoke"
            exit 1
            ;;
    esac
    
    log_success "All compatibility tests completed successfully!"
}

run_core_tests() {
    log_info "Running core compatibility tests..."
    docker-compose run --rm web bash -c "
        cd /app/samvera/hyrax-webapp &&
        bundle exec rspec spec/features/create_work_spec.rb spec/features/search_spec.rb \
            --format documentation
    "
}

run_integration_tests() {
    log_info "Running integration tests..."
    docker-compose run --rm web bash -c "
        cd /app/samvera/hyrax-webapp &&
        bundle exec rspec spec/controllers/ spec/models/ \
            --tag ~slow --format progress
    "
}

run_full_tests() {
    log_info "Running full test suite (this may take a while)..."
    docker-compose run --rm web bash -c "
        cd /app/samvera/hyrax-webapp &&
        bundle exec rspec --exclude-pattern 'spec/system/**/*_spec.rb' \
            --format progress
    "
}

run_smoke_tests() {
    log_info "Running smoke tests..."
    docker-compose run --rm web bash -c "
        cd /app/samvera/hyrax-webapp &&
        bundle exec rails runner '
            puts \"Testing basic functionality...\"
            puts \"Rails environment: #{Rails.env}\"
            puts \"Database connected: #{ActiveRecord::Base.connection.active?}\"
            puts \"Solr accessible: #{Blacklight.default_index.connection.get(\"admin/ping\")[\"status\"] == \"OK\"}\" rescue false
            puts \"All systems check: OK\"
        '
    "
}

# Show usage if no arguments and script is called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        echo "Usage: $0 [hyku_ref] [test_suite]"
        echo
        echo "Arguments:"
        echo "  hyku_ref    Git ref for Hyku (default: main)"
        echo "  test_suite  Test suite to run (default: core)"
        echo
        echo "Test suites:"
        echo "  core        Basic functionality tests"
        echo "  integration Broader integration tests"
        echo "  full        Complete test suite"
        echo "  smoke       Quick smoke tests"
        echo
        echo "Examples:"
        echo "  $0                    # Test with Hyku main, core tests"
        echo "  $0 v1.0.0.beta2      # Test with specific Hyku version"
        echo "  $0 main integration   # Test with Hyku main, integration tests"
        exit 0
    fi
    
    main "$@"
fi
