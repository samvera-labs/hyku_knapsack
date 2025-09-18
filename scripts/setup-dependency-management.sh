#!/bin/bash
# Setup script for cross-repo dependency management
# This script helps initialize the dependency management system

set -e

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

check_requirements() {
    log_info "Checking system requirements..."
    
    # Check for git
    if ! command -v git >/dev/null 2>&1; then
        log_error "Git is required but not installed"
        exit 1
    fi
    
    # Check for GitHub CLI (optional but recommended)
    if ! command -v gh >/dev/null 2>&1; then
        log_warning "GitHub CLI not found - some features may not work"
        log_info "Install with: brew install gh"
    fi
    
    # Check for Docker (required for testing)
    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker is required for compatibility testing"
        exit 1
    fi
    
    # Check for docker-compose
    if ! command -v docker-compose >/dev/null 2>&1; then
        log_error "docker-compose is required for compatibility testing"
        exit 1
    fi
    
    log_success "System requirements check passed"
}

setup_submodule() {
    log_info "Setting up Hyku submodule..."
    
    if [[ ! -f .gitmodules ]]; then
        log_error "No .gitmodules file found - this doesn't appear to be a knapsack repository"
        exit 1
    fi
    
    # Initialize submodule if not already done
    if [[ ! -f hyrax-webapp/.git ]]; then
        log_info "Initializing Hyku submodule..."
        git submodule init
        git submodule update
    else
        log_info "Hyku submodule already initialized"
    fi
    
    # Check submodule status
    cd hyrax-webapp
    CURRENT_SHA=$(git rev-parse HEAD)
    BRANCH=$(git branch --show-current || echo "detached")
    log_info "Hyku submodule status:"
    log_info "  SHA: $CURRENT_SHA"
    log_info "  Branch: $BRANCH"
    cd ..
    
    log_success "Hyku submodule setup complete"
}

setup_required_branch() {
    log_info "Setting up required_for_knapsack_instances branch..."
    
    # Check if branch exists locally
    if git branch --list | grep -q "required_for_knapsack_instances"; then
        log_info "required_for_knapsack_instances branch exists locally"
    else
        # Check if branch exists on remote
        if git ls-remote --heads origin required_for_knapsack_instances | grep -q "required_for_knapsack_instances"; then
            log_info "Checking out required_for_knapsack_instances from remote"
            git fetch origin required_for_knapsack_instances
            git checkout -b required_for_knapsack_instances origin/required_for_knapsack_instances
        else
            log_info "Creating new required_for_knapsack_instances branch"
            git checkout -b required_for_knapsack_instances
            git push -u origin required_for_knapsack_instances
        fi
    fi
    
    # Switch back to main
    git checkout main
    
    log_success "required_for_knapsack_instances branch setup complete"
}

setup_environment() {
    log_info "Setting up environment files..."
    
    # Create .env if it doesn't exist
    if [[ ! -f .env ]]; then
        if [[ -f .env.sample ]]; then
            cp .env.sample .env
            log_info "Created .env from .env.sample"
        else
            touch .env
            log_info "Created empty .env file"
        fi
    fi
    
    # Create .env.development if it doesn't exist
    if [[ ! -f .env.development ]]; then
        if [[ -f .env.development.sample ]]; then
            cp .env.development.sample .env.development
        else
            touch .env.development
        fi
        
        # Add knapsack-specific settings
        echo "" >> .env.development
        echo "# Knapsack local development settings" >> .env.development
        echo "BUNDLE_LOCAL__HYKU_KNAPSACK=/app/samvera" >> .env.development
        echo "BUNDLE_DISABLE_LOCAL_BRANCH_CHECK=true" >> .env.development
        
        log_info "Created .env.development with knapsack settings"
    else
        # Check if knapsack settings are present
        if ! grep -q "BUNDLE_LOCAL__HYKU_KNAPSACK" .env.development; then
            echo "" >> .env.development
            echo "# Knapsack local development settings" >> .env.development
            echo "BUNDLE_LOCAL__HYKU_KNAPSACK=/app/samvera" >> .env.development
            echo "BUNDLE_DISABLE_LOCAL_BRANCH_CHECK=true" >> .env.development
            log_info "Added knapsack settings to existing .env.development"
        fi
    fi
    
    log_success "Environment setup complete"
}

test_basic_functionality() {
    log_info "Testing basic functionality..."
    
    # Test compatibility script
    if [[ -x scripts/compatibility-test.sh ]]; then
        log_info "Running smoke test..."
        if ./scripts/compatibility-test.sh main smoke; then
            log_success "Basic functionality test passed"
        else
            log_warning "Basic functionality test failed - check Docker setup"
        fi
    else
        log_warning "Compatibility test script not found or not executable"
    fi
}

show_next_steps() {
    echo
    log_success "Setup complete! Here are your next steps:"
    echo
    echo "📋 IMMEDIATE ACTIONS:"
    echo "  1. Review the workflows in .github/workflows/"
    echo "  2. Check the documentation in docs/DEPENDENCY_MANAGEMENT.md"
    echo "  3. Test compatibility: ./scripts/compatibility-test.sh"
    echo
    echo "🔧 CONFIGURATION:"
    echo "  1. Enable workflow permissions in GitHub repository settings"
    echo "  2. Review and adjust workflow schedules if needed"
    echo "  3. Configure notifications for your team"
    echo
    echo "🧪 TESTING:"
    echo "  - Run compatibility tests: ./scripts/compatibility-test.sh"
    echo "  - Test with different Hyku versions: ./scripts/compatibility-test.sh v1.0.0.beta2"
    echo "  - Manual workflow dispatch: gh workflow run cross-repo-compatibility.yaml"
    echo
    echo "📚 LEARN MORE:"
    echo "  - Read: docs/DEPENDENCY_MANAGEMENT.md"
    echo "  - View workflows: .github/workflows/"
    echo "  - Test locally: ./scripts/compatibility-test.sh --help"
    echo
}

main() {
    echo "🚀 Cross-Repo Dependency Management Setup"
    echo "=========================================="
    echo
    
    check_requirements
    setup_submodule
    setup_required_branch
    setup_environment
    
    if [[ "$1" != "--no-test" ]]; then
        test_basic_functionality
    fi
    
    show_next_steps
}

# Handle command line arguments
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Usage: $0 [--no-test] [--help]"
    echo
    echo "Options:"
    echo "  --no-test    Skip the basic functionality test"
    echo "  --help       Show this help message"
    echo
    echo "This script sets up the cross-repo dependency management system"
    echo "for Hyku Knapsack, including submodules, branches, and environment."
    exit 0
fi

# Run main function
main "$@"
