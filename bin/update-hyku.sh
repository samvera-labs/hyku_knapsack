#!/bin/bash
# bin/update-hyku.sh
# Script to manage hyku submodule updates and testing

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
HYKU_REPO="https://github.com/samvera/hyku.git"
SUBMODULE_PATH="hyrax-webapp"
DEFAULT_BRANCHES=("main" "v1.0.0.beta2" "v1.0.0.beta1")

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] [BRANCH]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -t, --test-only     Only run tests, don't update submodule"
    echo "  -u, --update-only   Only update submodule, don't run tests"
    echo "  -a, --all-branches  Test against all configured branches"
    echo "  -f, --force         Force update even if tests fail"
    echo "  -v, --verbose       Enable verbose output"
    echo ""
    echo "Examples:"
    echo "  $0 main                    # Test and update to hyku main branch"
    echo "  $0 --test-only main        # Only test against hyku main branch"
    echo "  $0 --all-branches          # Test against all configured branches"
    echo "  $0 --update-only v1.0.0.beta2  # Update to specific version without testing"
}

# Function to check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a git repository"
        exit 1
    fi
}

# Function to check if submodule exists
check_submodule() {
    if [ ! -d "$SUBMODULE_PATH" ]; then
        print_error "Submodule $SUBMODULE_PATH not found"
        exit 1
    fi
}

# Function to get current hyku commit
get_current_commit() {
    cd "$SUBMODULE_PATH"
    git rev-parse HEAD
}

# Function to get hyku version info
get_hyku_version() {
    cd "$SUBMODULE_PATH"
    local version=$(git describe --tags --exact-match 2>/dev/null || git rev-parse --short HEAD)
    local branch=$(git branch --show-current 2>/dev/null || echo "detached")
    echo "$version ($branch)"
}

# Function to update submodule to specific branch/commit
update_submodule() {
    local target="$1"
    local commit_before=$(get_current_commit)
    
    print_status "Updating hyku submodule to: $target"
    
    cd "$SUBMODULE_PATH"
    git fetch origin
    
    # Try to checkout as branch first, then as tag, then as commit
    if git show-ref --verify --quiet "refs/remotes/origin/$target"; then
        git checkout "origin/$target"
    elif git show-ref --verify --quiet "refs/tags/$target"; then
        git checkout "$target"
    else
        git checkout "$target"
    fi
    
    local commit_after=$(git rev-parse HEAD)
    cd ..
    
    if [ "$commit_before" != "$commit_after" ]; then
        git add "$SUBMODULE_PATH"
        git commit -m "Update hyku submodule to $target ($(cd $SUBMODULE_PATH && git rev-parse --short HEAD))" || print_warning "No changes to commit"
        print_success "Updated hyku submodule from $(echo $commit_before | cut -c1-7) to $(echo $commit_after | cut -c1-7)"
    else
        print_warning "Hyku submodule already at target: $target"
    fi
}

# Function to run tests
run_tests() {
    local hyku_version="$1"
    print_status "Running tests with hyku: $hyku_version"
    
    # Check if we're in a Docker environment or need to use Docker
    if command -v docker-compose >/dev/null 2>&1; then
        print_status "Running tests with Docker Compose..."
        
        # Build images
        if ! docker-compose build; then
            print_error "Docker build failed"
            return 1
        fi
        
        # Run tests
        if ! docker-compose run --rm web bundle exec rspec; then
            print_error "Tests failed with hyku: $hyku_version"
            return 1
        fi
    else
        print_status "Running tests directly..."
        
        # Install dependencies
        if ! bundle install; then
            print_error "Bundle install failed"
            return 1
        fi
        
        # Run tests
        if ! bundle exec rspec; then
            print_error "Tests failed with hyku: $hyku_version"
            return 1
        fi
    fi
    
    print_success "All tests passed with hyku: $hyku_version"
    return 0
}

# Function to test against multiple branches
test_all_branches() {
    local failed_branches=()
    
    print_status "Testing against all configured branches: ${DEFAULT_BRANCHES[*]}"
    
    for branch in "${DEFAULT_BRANCHES[@]}"; do
        print_status "Testing with hyku branch: $branch"
        
        # Update submodule
        update_submodule "$branch"
        
        # Run tests
        if ! run_tests "$(get_hyku_version)"; then
            failed_branches+=("$branch")
            if [ "$FORCE" != "true" ]; then
                print_error "Tests failed with hyku $branch. Use --force to continue."
                return 1
            fi
        fi
    done
    
    if [ ${#failed_branches[@]} -eq 0 ]; then
        print_success "All tests passed against all branches!"
    else
        print_warning "Tests failed for branches: ${failed_branches[*]}"
        return 1
    fi
}

# Function to show current status
show_status() {
    print_status "Current hyku status:"
    echo "  Version: $(get_hyku_version)"
    echo "  Commit: $(get_current_commit)"
    echo "  Path: $SUBMODULE_PATH"
}

# Parse command line arguments
TEST_ONLY=false
UPDATE_ONLY=false
ALL_BRANCHES=false
FORCE=false
VERBOSE=false
TARGET_BRANCH=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -t|--test-only)
            TEST_ONLY=true
            shift
            ;;
        -u|--update-only)
            UPDATE_ONLY=true
            shift
            ;;
        -a|--all-branches)
            ALL_BRANCHES=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            set -x
            shift
            ;;
        -*)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
        *)
            TARGET_BRANCH="$1"
            shift
            ;;
    esac
done

# Main execution
main() {
    print_status "Starting hyku submodule management..."
    
    # Validate environment
    check_git_repo
    check_submodule
    
    # Show current status
    show_status
    
    # Handle different modes
    if [ "$ALL_BRANCHES" = true ]; then
        test_all_branches
    elif [ -n "$TARGET_BRANCH" ]; then
        if [ "$TEST_ONLY" = true ]; then
            # Only test, don't update
            update_submodule "$TARGET_BRANCH"
            run_tests "$(get_hyku_version)"
        elif [ "$UPDATE_ONLY" = true ]; then
            # Only update, don't test
            update_submodule "$TARGET_BRANCH"
        else
            # Update and test
            update_submodule "$TARGET_BRANCH"
            run_tests "$(get_hyku_version)"
        fi
    else
        print_error "No target branch specified. Use --help for usage information."
        exit 1
    fi
    
    print_success "Hyku submodule management completed successfully!"
}

# Run main function
main "$@"
