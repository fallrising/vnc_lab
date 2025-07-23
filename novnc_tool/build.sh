#!/bin/bash

# VNC Lab - novnc_tool Build Script
# Build Docker image for enhanced tools VNC environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="vnc-tool"
DEFAULT_TAG="latest"
DOCKERFILE="Dockerfile"

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
    echo "  -f, --file FILE     Dockerfile to use (default: $DOCKERFILE)"
    echo "  --no-cache          Build without cache"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Build with default settings"
    echo "  $0 -t v1.0.0         # Build with specific tag"
    echo "  $0 --no-cache        # Build without cache"
}

# Parse command line arguments
TAG=$DEFAULT_TAG
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
else
    print_error "Build failed!"
    exit 1
fi 