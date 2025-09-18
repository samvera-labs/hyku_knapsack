#!/bin/bash
# bin/test-setup.sh
# Test script to verify the cross-repo dependency management setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Testing Cross-Repo Setup${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Test 1: Check if scripts exist and are executable
test_scripts() {
    print_status "Testing management scripts..."
    
    local scripts=("bin/check-hyku-versions.sh" "bin/update-hyku.sh")
    
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            if [ -x "$script" ]; then
                print_success "$script exists and is executable"
            else
                print_error "$script exists but is not executable"
                return 1
            fi
        else
            print_error "$script does not exist"
            return 1
        fi
    done
}

# Test 2: Check if GitHub Actions workflows exist
test_workflows() {
    print_status "Testing GitHub Actions workflows..."
    
    local workflows=(
        ".github/workflows/test-hyku-versions.yml"
        ".github/workflows/auto-update-hyku.yml"
        ".github/workflows/hyku-notification.yml"
    )
    
    for workflow in "${workflows[@]}"; do
        if [ -f "$workflow" ]; then
            print_success "$workflow exists"
        else
            print_error "$workflow does not exist"
            return 1
        fi
    done
}

# Test 3: Check if submodule exists
test_submodule() {
    print_status "Testing hyku submodule..."
    
    if [ -d "hyrax-webapp" ]; then
        if [ -d "hyrax-webapp/.git" ]; then
            print_success "Hyku submodule exists and is a git repository"
        else
            print_warning "Hyku submodule exists but is not a git repository (may need initialization)"
            # Check if it's a submodule
            if git submodule status hyrax-webapp > /dev/null 2>&1; then
                print_success "Hyku submodule is properly configured"
            else
                print_error "Hyku submodule is not properly configured"
                return 1
            fi
        fi
    else
        print_error "Hyku submodule does not exist"
        return 1
    fi
}

# Test 4: Check if scripts can run without errors
test_script_execution() {
    print_status "Testing script execution..."
    
    # Test check-hyku-versions.sh
    if ./bin/check-hyku-versions.sh --help > /dev/null 2>&1; then
        print_success "check-hyku-versions.sh help works"
    else
        print_error "check-hyku-versions.sh help failed"
        return 1
    fi
    
    # Test update-hyku.sh
    if ./bin/update-hyku.sh --help > /dev/null 2>&1; then
        print_success "update-hyku.sh help works"
    else
        print_error "update-hyku.sh help failed"
        return 1
    fi
}

# Test 5: Check Docker setup
test_docker() {
    print_status "Testing Docker setup..."
    
    if command -v docker-compose >/dev/null 2>&1; then
        print_success "Docker Compose is available"
        
        if [ -f "docker-compose.yml" ]; then
            print_success "docker-compose.yml exists"
        else
            print_error "docker-compose.yml does not exist"
            return 1
        fi
    else
        print_warning "Docker Compose not available (optional for local testing)"
    fi
}

# Test 6: Check git configuration
test_git() {
    print_status "Testing git configuration..."
    
    if git rev-parse --git-dir > /dev/null 2>&1; then
        print_success "In a git repository"
        
        if git config --get remote.origin.url > /dev/null 2>&1; then
            print_success "Git remote origin is configured"
        else
            print_warning "Git remote origin not configured"
        fi
    else
        print_error "Not in a git repository"
        return 1
    fi
}

# Main test function
main() {
    print_header
    
    local tests=(
        "test_scripts"
        "test_workflows"
        "test_submodule"
        "test_script_execution"
        "test_docker"
        "test_git"
    )
    
    local passed=0
    local total=${#tests[@]}
    
    for test in "${tests[@]}"; do
        if $test; then
            ((passed++))
        else
            print_error "Test $test failed"
        fi
        echo ""
    done
    
    echo "=================================="
    echo "Test Results: $passed/$total passed"
    echo "=================================="
    
    if [ $passed -eq $total ]; then
        print_success "All tests passed! Setup is ready."
        echo ""
        echo "Next steps:"
        echo "1. Run './bin/check-hyku-versions.sh' to see current hyku status"
        echo "2. Run './bin/update-hyku.sh --help' to see update options"
        echo "3. Push changes to trigger GitHub Actions workflows"
        return 0
    else
        print_error "Some tests failed. Please fix the issues above."
        return 1
    fi
}

# Run main function
main "$@"
