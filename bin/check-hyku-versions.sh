#!/bin/bash
# bin/check-hyku-versions.sh
# Quick script to check available hyku versions and current status

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

SUBMODULE_PATH="hyrax-webapp"

print_header() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}  Hyku Version Checker${NC}"
    echo -e "${CYAN}================================${NC}"
}

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

# Function to get current hyku info
get_current_info() {
    if [ ! -d "$SUBMODULE_PATH" ]; then
        print_error "Submodule $SUBMODULE_PATH not found"
        return 1
    fi
    
    cd "$SUBMODULE_PATH"
    local commit=$(git rev-parse HEAD)
    local short_commit=$(git rev-parse --short HEAD)
    local version=$(git describe --tags --exact-match 2>/dev/null || echo "commit $short_commit")
    local branch=$(git branch --show-current 2>/dev/null || echo "detached")
    local date=$(git log -1 --format=%ci)
    
    echo "Current Version: $version"
    echo "Current Branch: $branch"
    echo "Current Commit: $short_commit"
    echo "Last Updated: $date"
    cd ..
}

# Function to check for updates
check_updates() {
    print_status "Checking for hyku updates..."
    
    cd "$SUBMODULE_PATH"
    git fetch origin --quiet
    
    local current_commit=$(git rev-parse HEAD)
    local main_commit=$(git rev-parse origin/main)
    local beta2_commit=$(git rev-parse origin/v1.0.0.beta2 2>/dev/null || echo "not found")
    local beta1_commit=$(git rev-parse origin/v1.0.0.beta1 2>/dev/null || echo "not found")
    
    echo ""
    echo "Available Updates:"
    echo "------------------"
    
    if [ "$current_commit" != "$main_commit" ]; then
        local main_ahead=$(git rev-list --count HEAD..origin/main)
        echo -e "  ${GREEN}main${NC}: $main_ahead commits ahead"
    else
        echo -e "  ${GREEN}main${NC}: up to date"
    fi
    
    if [ "$beta2_commit" != "not found" ] && [ "$current_commit" != "$beta2_commit" ]; then
        local beta2_ahead=$(git rev-list --count HEAD..origin/v1.0.0.beta2 2>/dev/null || echo "0")
        echo -e "  ${YELLOW}v1.0.0.beta2${NC}: $beta2_ahead commits ahead"
    elif [ "$beta2_commit" != "not found" ]; then
        echo -e "  ${YELLOW}v1.0.0.beta2${NC}: up to date"
    else
        echo -e "  ${YELLOW}v1.0.0.beta2${NC}: not available"
    fi
    
    if [ "$beta1_commit" != "not found" ] && [ "$current_commit" != "$beta1_commit" ]; then
        local beta1_ahead=$(git rev-list --count HEAD..origin/v1.0.0.beta1 2>/dev/null || echo "0")
        echo -e "  ${YELLOW}v1.0.0.beta1${NC}: $beta1_ahead commits ahead"
    elif [ "$beta1_commit" != "not found" ]; then
        echo -e "  ${YELLOW}v1.0.0.beta1${NC}: up to date"
    else
        echo -e "  ${YELLOW}v1.0.0.beta1${NC}: not available"
    fi
    
    cd ..
}

# Function to show recent commits
show_recent_commits() {
    print_status "Recent hyku commits:"
    
    cd "$SUBMODULE_PATH"
    echo ""
    git log --oneline -10 --graph --decorate
    cd ..
}

# Function to show available branches and tags
show_available_versions() {
    print_status "Available hyku versions:"
    
    cd "$SUBMODULE_PATH"
    git fetch origin --quiet
    
    echo ""
    echo "Branches:"
    git branch -r | grep -E "(main|v1\.0\.0\.beta)" | sed 's/^/  /'
    
    echo ""
    echo "Recent Tags:"
    git tag -l "v1.0.0.*" | tail -10 | sed 's/^/  /'
    
    cd ..
}

# Function to show help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -u, --updates       Check for available updates"
    echo "  -c, --commits       Show recent commits"
    echo "  -v, --versions      Show available versions"
    echo "  -a, --all           Show all information (default)"
    echo ""
    echo "Examples:"
    echo "  $0                  # Show all information"
    echo "  $0 --updates        # Only check for updates"
    echo "  $0 --commits        # Only show recent commits"
}

# Parse command line arguments
SHOW_UPDATES=false
SHOW_COMMITS=false
SHOW_VERSIONS=false
SHOW_ALL=true

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -u|--updates)
            SHOW_UPDATES=true
            SHOW_ALL=false
            shift
            ;;
        -c|--commits)
            SHOW_COMMITS=true
            SHOW_ALL=false
            shift
            ;;
        -v|--versions)
            SHOW_VERSIONS=true
            SHOW_ALL=false
            shift
            ;;
        -a|--all)
            SHOW_ALL=true
            shift
            ;;
        -*)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            print_error "Unknown argument: $1"
            show_help
            exit 1
            ;;
    esac
done

# Main execution
main() {
    print_header
    
    if [ "$SHOW_ALL" = true ] || [ "$SHOW_UPDATES" = false ] && [ "$SHOW_COMMITS" = false ] && [ "$SHOW_VERSIONS" = false ]; then
        echo "Current Status:"
        echo "---------------"
        get_current_info
        echo ""
    fi
    
    if [ "$SHOW_ALL" = true ] || [ "$SHOW_UPDATES" = true ]; then
        check_updates
        echo ""
    fi
    
    if [ "$SHOW_ALL" = true ] || [ "$SHOW_COMMITS" = true ]; then
        show_recent_commits
        echo ""
    fi
    
    if [ "$SHOW_ALL" = true ] || [ "$SHOW_VERSIONS" = true ]; then
        show_available_versions
        echo ""
    fi
    
    echo "Use './bin/update-hyku.sh --help' for update options"
}

# Run main function
main "$@"
