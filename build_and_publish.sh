#!/bin/bash

# Automated script to build, convert, and publish alpaca_kernel_2 conda package
# Usage: ./build_and_publish.sh [options]
# Options:
#   --python-version VERSION    Python version for build (default: 3.10)
#   --organization ORG          Anaconda organization (default: nb_tudelft)
#   --label LABEL              Anaconda label (default: main)
#   --skip-build               Skip build step if artifacts already exist
#   --skip-convert             Skip conversion step
#   --skip-upload              Skip upload step
#   --dry-run                  Show what would be done without executing

set -euo pipefail

# Default configuration
PYTHON_VERSION="3.10"
ORGANIZATION="nb_tudelft"
LABEL="main"
SKIP_BUILD=false
SKIP_CONVERT=false
SKIP_UPLOAD=false
DRY_RUN=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/conda-bld"
CONVERT_DIR="${SCRIPT_DIR}/dist/converted"

# Color codes for output
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

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --python-version)
            PYTHON_VERSION="$2"
            shift 2
            ;;
        --organization)
            ORGANIZATION="$2"
            shift 2
            ;;
        --label)
            LABEL="$2"
            shift 2
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --skip-convert)
            SKIP_CONVERT=true
            shift
            ;;
        --skip-upload)
            SKIP_UPLOAD=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --python-version VERSION    Python version for build (default: 3.10)"
            echo "  --organization ORG          Anaconda organization (default: nb_tudelft)"
            echo "  --label LABEL              Anaconda label (default: main)"
            echo "  --skip-build               Skip build step if artifacts already exist"
            echo "  --skip-convert             Skip conversion step"
            echo "  --skip-upload              Skip upload step"
            echo "  --dry-run                  Show what would be done without executing"
            echo "  -h, --help                 Show this help message"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Function to execute or show command
execute_or_show() {
    local cmd="$1"
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN: $cmd"
    else
        log_info "Executing: $cmd"
        eval "$cmd"
    fi
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check conda
    if ! command -v conda &> /dev/null; then
        log_error "conda not found. Please install Anaconda/Miniconda."
        exit 1
    fi
    
    # Check anaconda client
    if ! command -v anaconda &> /dev/null; then
        log_error "anaconda client not found. Please install with: conda install anaconda-client"
        exit 1
    fi
    
    # Check if logged in to anaconda
    if ! anaconda whoami &> /dev/null; then
        log_error "Not logged in to Anaconda Cloud. Please run: anaconda login"
        exit 1
    fi
    
    # Check if in the right directory (has meta.yaml)
    if [[ ! -f "${SCRIPT_DIR}/meta.yaml" ]]; then
        log_error "meta.yaml not found in ${SCRIPT_DIR}. Please run this script from the package root directory."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Build conda packages
build_packages() {
    if [[ "$SKIP_BUILD" == "true" ]]; then
        log_info "Skipping build step as requested"
        return 0
    fi
    
    log_info "Building conda packages..."
    
    # Clean previous builds
    execute_or_show "conda build purge || true"
    
    # Build .tar.bz2 format (required for conversion)
    log_info "Building .tar.bz2 package..."
    execute_or_show "conda build . --python=${PYTHON_VERSION} --no-anaconda-upload --no-include-recipe --package-format tar.bz2"
    
    # Build .conda format (modern format)
    log_info "Building .conda package..."
    execute_or_show "conda build . --python=${PYTHON_VERSION} --no-anaconda-upload --no-include-recipe --package-format conda"
    
    log_success "Package builds completed"
}

# Convert packages for all platforms
convert_packages() {
    if [[ "$SKIP_CONVERT" == "true" ]]; then
        log_info "Skipping conversion step as requested"
        return 0
    fi
    
    log_info "Converting packages for all platforms..."
    
    # Find the built tar.bz2 package
    local package_pattern
    package_pattern="$(conda info --base)/conda-bld/linux-64/alpaca_kernel_2-*-py${PYTHON_VERSION//.}_0.tar.bz2"
    local tar_package
    tar_package=$(ls $package_pattern 2>/dev/null | head -1)
    
    if [[ -z "$tar_package" || ! -f "$tar_package" ]]; then
        log_error "Built tar.bz2 package not found at: $package_pattern"
        exit 1
    fi
    
    log_info "Found package: $tar_package"
    
    # Create conversion directory
    execute_or_show "mkdir -p '${CONVERT_DIR}'"
    
    # Convert to all platforms
    log_info "Converting to all supported platforms..."
    execute_or_show "conda convert '$tar_package' --platform all -o '${CONVERT_DIR}'"
    
    log_success "Package conversion completed"
}

# Upload packages to Anaconda Cloud
upload_packages() {
    if [[ "$SKIP_UPLOAD" == "true" ]]; then
        log_info "Skipping upload step as requested"
        return 0
    fi
    
    log_info "Uploading packages to ${ORGANIZATION}..."
    
    # Find all packages to upload
    local conda_base
    conda_base="$(conda info --base)"
    
    # Upload original builds
    local tar_package conda_package
    tar_package=$(ls "${conda_base}/conda-bld/linux-64/alpaca_kernel_2-"*"-py${PYTHON_VERSION//.}_0.tar.bz2" 2>/dev/null | head -1)
    conda_package=$(ls "${conda_base}/conda-bld/linux-64/alpaca_kernel_2-"*"-py${PYTHON_VERSION//.}_0.conda" 2>/dev/null | head -1)
    
    if [[ -n "$tar_package" && -f "$tar_package" ]]; then
        log_info "Uploading original tar.bz2 package..."
        execute_or_show "anaconda upload -u '${ORGANIZATION}' -l '${LABEL}' --skip-existing '$tar_package'"
    fi
    
    if [[ -n "$conda_package" && -f "$conda_package" ]]; then
        log_info "Uploading original .conda package..."
        execute_or_show "anaconda upload -u '${ORGANIZATION}' -l '${LABEL}' --skip-existing '$conda_package'"
    fi
    
    # Upload converted packages
    if [[ -d "$CONVERT_DIR" ]]; then
        log_info "Uploading converted packages..."
        local converted_packages
        converted_packages=$(find "$CONVERT_DIR" -name "*.tar.bz2" -type f)
        
        if [[ -n "$converted_packages" ]]; then
            while IFS= read -r package; do
                log_info "Uploading: $(basename "$package")"
                execute_or_show "anaconda upload -u '${ORGANIZATION}' -l '${LABEL}' --skip-existing '$package'"
            done <<< "$converted_packages"
        else
            log_warning "No converted packages found in $CONVERT_DIR"
        fi
    fi
    
    log_success "Package upload completed"
}

# Verify uploads
verify_uploads() {
    log_info "Verifying uploads..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN: Would verify package visibility on Anaconda Cloud"
        return 0
    fi
    
    # Check if package exists on Anaconda Cloud
    if anaconda show "${ORGANIZATION}/alpaca_kernel_2" &> /dev/null; then
        log_success "Package verified on Anaconda Cloud"
        
        # Show package info
        log_info "Package information:"
        anaconda show "${ORGANIZATION}/alpaca_kernel_2"
    else
        log_error "Package not found on Anaconda Cloud"
        exit 1
    fi
}

# Clean up temporary files
cleanup() {
    log_info "Cleaning up..."
    
    # Optionally clean conda build cache
    # execute_or_show "conda build purge"
    
    log_info "Cleanup completed"
}

# Main execution
main() {
    log_info "Starting conda package build and publish workflow"
    log_info "Configuration:"
    log_info "  Python version: $PYTHON_VERSION"
    log_info "  Organization: $ORGANIZATION"
    log_info "  Label: $LABEL"
    log_info "  Working directory: $SCRIPT_DIR"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "DRY RUN MODE - No actual changes will be made"
    fi
    
    check_prerequisites
    build_packages
    convert_packages
    upload_packages
    verify_uploads
    cleanup
    
    log_success "All operations completed successfully!"
    log_info "Package available at: https://anaconda.org/${ORGANIZATION}/alpaca_kernel_2"
}

# Run main function
main "$@"