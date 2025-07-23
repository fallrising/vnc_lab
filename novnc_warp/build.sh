#!/bin/bash

# VNC Lab - novnc_warp Build Script
# Build Docker image for Warp terminal VNC environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="vnc-warp"
DEFAULT_TAG="latest"
DEFAULT_DOCKERFILE="Dockerfile"

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
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -t, --tag TAG       Image tag (default: $DEFAULT_TAG)"
    echo "  -f, --file FILE     Dockerfile to use (default: $DEFAULT_DOCKERFILE)"
    echo "  --gpu               Build GPU version (uses Dockerfile.gpu)"
    echo "  --no-cache          Build without cache"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Build standard version"
    echo "  $0 --gpu             # Build GPU version"
    echo "  $0 -t v1.0.0         # Build with specific tag"
    echo "  $0 --gpu -t gpu-v1.0 # Build GPU version with tag"
    echo "  $0 --no-cache        # Build without cache"
}

# Parse command line arguments
TAG=$DEFAULT_TAG
DOCKERFILE=$DEFAULT_DOCKERFILE
BUILD_ARGS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--tag)
            TAG="$2"
            shift 2
            ;;
        -f|--file)
            DOCKERFILE="$2"
            shift 2
            ;;
        --gpu)
            DOCKERFILE="Dockerfile.gpu"
            IMAGE_NAME="vnc-warp-gpu"
            shift
            ;;
        --no-cache)
            BUILD_ARGS="$BUILD_ARGS --no-cache"
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Check if Dockerfile exists
if [[ ! -f "$DOCKERFILE" ]]; then
    print_error "Dockerfile '$DOCKERFILE' not found!"
    exit 1
fi

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running or not accessible!"
    exit 1
fi

# Check if base image exists
if ! docker images "vnc-base:latest" | grep -q "vnc-base"; then
    print_warning "Base image 'vnc-base:latest' not found!"
    print_status "Please build the base image first:"
    print_status "  cd ../novnc_base && ./build.sh"
    exit 1
fi

# Build the image
print_status "Building $IMAGE_NAME:$TAG..."
print_status "Using Dockerfile: $DOCKERFILE"

FULL_IMAGE_NAME="$IMAGE_NAME:$TAG"

if docker build $BUILD_ARGS -f "$DOCKERFILE" -t "$FULL_IMAGE_NAME" .; then
    print_success "Image built successfully: $FULL_IMAGE_NAME"
    
    # Show image info
    print_status "Image details:"
    docker images "$FULL_IMAGE_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
    
    print_success "Build completed successfully!"
    print_status "You can now run the container using: ./run.sh"
else
    print_error "Build failed!"
    exit 1
fi 