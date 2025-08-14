#!/bin/bash

# VNC Lab - Multi-Platform Docker Push Script
# Builds and pushes all multi-platform images to Docker Hub using buildx

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOCKER_HUB_ACCOUNT="u80250docker"

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
    echo "  --dry-run               Show what would be pushed without actually pushing"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                      # Push all multi-arch images"
    echo "  $0 --dry-run           # Show what would be pushed"
}

# Parse command line arguments
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
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

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running or not accessible!"
    exit 1
fi

# Check if buildx builder is available and running
if ! docker buildx inspect multiarch_builder >/dev/null 2>&1; then
    print_error "Docker buildx builder 'multiarch_builder' not found or not running!"
    print_status "Please run './build-multiplatform.sh' first to create and start the builder."
    exit 1
fi

# Ensure buildx is using the multiarch builder
docker buildx use multiarch_builder
print_success "Docker Hub access confirmed and buildx builder is ready."

# Function to build and push multi-platform images
build_and_push() {
    local image_name="$1"
    local build_context="$2"
    local dockerfile="$3"
    
    print_status "Building and pushing ${DOCKER_HUB_ACCOUNT}/${image_name}..."
    
    if [[ "$DRY_RUN" == true ]]; then
        print_status "[DRY RUN] Would build and push ${DOCKER_HUB_ACCOUNT}/${image_name}"
        return 0
    fi
    
    if [ -n "$dockerfile" ]; then
        docker buildx build \
            --platform linux/amd64,linux/arm64 \
            -t "${DOCKER_HUB_ACCOUNT}/${image_name}:latest" \
            -f "$dockerfile" \
            "$build_context" \
            --push
    else
        docker buildx build \
            --platform linux/amd64,linux/arm64 \
            -t "${DOCKER_HUB_ACCOUNT}/${image_name}:latest" \
            "$build_context" \
            --push
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Successfully built and pushed ${DOCKER_HUB_ACCOUNT}/${image_name}"
    else
        print_error "Failed to build ${DOCKER_HUB_ACCOUNT}/${image_name}"
        return 1
    fi
}

print_status "Starting VNC Lab multi-platform build and push to Docker Hub..."

if [[ "$DRY_RUN" == true ]]; then
    print_status "DRY RUN MODE - No images will actually be built or pushed"
fi

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

print_success "\nVNC Lab multi-platform build and push completed!"

print_status "\n=== Docker Hub Images ==="
echo "The following multi-platform images are now available:"
echo "  - ${DOCKER_HUB_ACCOUNT}/novnc-base:latest"
echo "  - ${DOCKER_HUB_ACCOUNT}/novnc-cursor:latest"
echo "  - ${DOCKER_HUB_ACCOUNT}/novnc-cursor-gpu:latest"
echo "  - ${DOCKER_HUB_ACCOUNT}/novnc-llm-cli:latest"
echo "  - ${DOCKER_HUB_ACCOUNT}/novnc-llm-cli-add-validation:latest"
echo "  - ${DOCKER_HUB_ACCOUNT}/novnc-tool:latest"
echo "  - ${DOCKER_HUB_ACCOUNT}/novnc-warp:latest"
echo "  - ${DOCKER_HUB_ACCOUNT}/novnc-warp-gpu:latest"

print_status "\nAll images support both linux/amd64 and linux/arm64 architectures"
print_status "Docker Hub: https://hub.docker.com/u/$DOCKER_HUB_ACCOUNT"
 