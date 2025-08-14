#!/bin/bash

# Multi-platform Docker build script
# Builds all VNC containers for AMD64 and ARM64 architectures

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Docker Hub username
DOCKER_HUB_USER="u80250docker"

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

# Function to build and push multi-platform images
build_and_push() {
    local image_name="$1"
    local build_context="$2"
    local dockerfile="$3"
    
    print_status "Building and pushing ${DOCKER_HUB_USER}/${image_name}..."
    
    if [ -n "$dockerfile" ]; then
        docker buildx build \
            --platform linux/amd64,linux/arm64 \
            -t "${DOCKER_HUB_USER}/${image_name}:latest" \
            -f "$dockerfile" \
            "$build_context" \
            --push
    else
        docker buildx build \
            --platform linux/amd64,linux/arm64 \
            -t "${DOCKER_HUB_USER}/${image_name}:latest" \
            "$build_context" \
            --push
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Successfully built and pushed ${DOCKER_HUB_USER}/${image_name}"
    else
        print_error "Failed to build ${DOCKER_HUB_USER}/${image_name}"
        return 1
    fi
}

# Check if docker buildx is available
if ! docker buildx version >/dev/null 2>&1; then
    print_error "Docker buildx is not available. Please install Docker Desktop or enable buildx."
    exit 1
fi

# Create buildx builder if it doesn't exist
print_status "Setting up multi-platform builder..."
if ! docker buildx ls | grep -q "multiarch_builder"; then
    docker buildx create --name multiarch_builder --use --driver docker-container
fi

docker buildx use multiarch_builder
docker buildx inspect --bootstrap

print_status "Starting multi-platform builds..."

# Build images in order (base first, then dependent images)
print_status "=== Building Base Images ==="

# 1. novnc-base (foundation for others)
build_and_push "novnc-base" "novnc_base/"

print_status "=== Building Application Images ==="

# 2. novnc-cursor
build_and_push "novnc-cursor" "novnc_cursor/"

# 3. novnc-cursor-gpu  
build_and_push "novnc-cursor-gpu" "novnc_cursor/" "novnc_cursor/Dockerfile.gpu"

# 4. novnc-llm-cli
build_and_push "novnc-llm-cli" "novnc_llm_cli/"

# 5. novnc-llm-cli-add-validation
build_and_push "novnc-llm-cli-add-validation" "novnc_llm_cli/" "novnc_llm_cli/Dockerfile.add_validation"

# 6. novnc-tool
build_and_push "novnc-tool" "novnc_tool/"

# 7. novnc-warp
build_and_push "novnc-warp" "novnc_warp/"

# 8. novnc-warp-gpu
build_and_push "novnc-warp-gpu" "novnc_warp/" "novnc_warp/Dockerfile.gpu"

print_success "All multi-platform builds completed successfully!"

print_status "=== Build Summary ==="
echo "The following images are now available for linux/amd64 and linux/arm64:"
echo "  - ${DOCKER_HUB_USER}/novnc-base:latest"
echo "  - ${DOCKER_HUB_USER}/novnc-cursor:latest"
echo "  - ${DOCKER_HUB_USER}/novnc-cursor-gpu:latest"
echo "  - ${DOCKER_HUB_USER}/novnc-llm-cli:latest"
echo "  - ${DOCKER_HUB_USER}/novnc-llm-cli-add-validation:latest"
echo "  - ${DOCKER_HUB_USER}/novnc-tool:latest"
echo "  - ${DOCKER_HUB_USER}/novnc-warp:latest"
echo "  - ${DOCKER_HUB_USER}/novnc-warp-gpu:latest"

print_status "You can now run: docker pull ${DOCKER_HUB_USER}/<image-name>:latest on any AMD64 or ARM64 system"