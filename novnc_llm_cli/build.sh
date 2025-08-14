#!/bin/bash

# VNC Lab - novnc_llm_cli Build Script
# Build Docker image for AI tools integrated VNC environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOCKER_HUB_ACCOUNT="u80250docker"
IMAGE_NAME="vnc-llm-cli"
DEFAULT_TAG="latest"
DEFAULT_DOCKERFILE="Dockerfile"
DEFAULT_ARCH="amd64"

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
    echo "  -t, --tag TAG           Image tag (default: $DEFAULT_TAG)"
    echo "  -f, --file FILE         Dockerfile to use (default: $DEFAULT_DOCKERFILE)"
    echo "  --validation            Use Dockerfile.add_validation"
    echo "  --arch ARCH             Architecture to build for (default: $DEFAULT_ARCH)"
    echo "  --push                  Push the image to Docker Hub"
    echo "  --no-cache              Build without cache"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                      # Build for amd64"
    echo "  $0 --arch arm64          # Build for arm64"
    echo "  $0 --validation        # Build with validation features for amd64"
    echo "  $0 --push                 # Build and push for amd64"
}

# Parse command line arguments
TAG=$DEFAULT_TAG
DOCKERFILE=$DEFAULT_DOCKERFILE
ARCH=$DEFAULT_ARCH
PUSH_IMAGE=false
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
        --validation)
            DOCKERFILE="Dockerfile.add_validation"
            shift
            ;; 
        --arch)
            ARCH="$2"
            shift 2
            ;; 
        --push)
            PUSH_IMAGE=true
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
BASE_IMAGE_TAG="$DEFAULT_TAG-$ARCH"
if ! docker images "$DOCKER_HUB_ACCOUNT/vnc-base:$BASE_IMAGE_TAG" | grep -q "vnc-base"; then
    print_warning "Base image '$DOCKER_HUB_ACCOUNT/vnc-base:$BASE_IMAGE_TAG' not found!"
    print_status "Please build the base image first for architecture $ARCH:"
    print_status "  cd ../novnc_base && ./build.sh --arch $ARCH"
    exit 1
fi

# Build the image
PLATFORM="linux/$ARCH"
FULL_IMAGE_NAME="$DOCKER_HUB_ACCOUNT/$IMAGE_NAME:$TAG-$ARCH"

print_status "Building $FULL_IMAGE_NAME for platform $PLATFORM..."
print_status "Using Dockerfile: $DOCKERFILE"

docker buildx build \
    --platform "$PLATFORM" \
    --build-arg BASE_IMAGE=$DOCKER_HUB_ACCOUNT/vnc-base:$DEFAULT_TAG-$ARCH \
    -f "$DOCKERFILE" \
    -t "$FULL_IMAGE_NAME" \
    $BUILD_ARGS \
    .

if $PUSH_IMAGE; then
    print_status "Pushing $FULL_IMAGE_NAME..."
    docker push "$FULL_IMAGE_NAME"
    print_success "Image pushed successfully: $FULL_IMAGE_NAME"
else
    print_success "Image built successfully: $FULL_IMAGE_NAME"
    print_warning "To push the image, use the --push flag."
fi


# Show image info
print_status "Image details:"
docker images "$FULL_IMAGE_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

print_success "Build completed successfully!"