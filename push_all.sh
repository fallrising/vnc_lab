#!/bin/bash

# VNC Lab - Push All Images to Docker Hub
# Push all container images to u80250docker Docker Hub account

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOCKER_HUB_USERNAME="u80250docker"
DOCKER_HUB_REGISTRY="docker.io"

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
    echo "  --all                   Push all images (default)"
    echo "  --base                  Push base image only"
    echo "  --cursor                Push Cursor IDE images only"
    echo "  --llm                   Push LLM CLI image only"
    echo "  --tool                  Push tool image only"
    echo "  --warp                  Push Warp images only"
    echo "  --gpu                   Include GPU versions"
    echo "  --latest                Push latest tags only"
    echo "  --version VERSION       Push specific version"
    echo "  --dry-run               Show what would be pushed without actually pushing"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                      # Push all images"
    echo "  $0 --gpu               # Push all images including GPU versions"
    echo "  $0 --cursor --gpu      # Push Cursor IDE images with GPU versions"
    echo "  $0 --version v1.0.0    # Push specific version"
    echo "  $0 --dry-run           # Show what would be pushed"
}

# Parse command line arguments
PUSH_ALL=true
PUSH_BASE=false
PUSH_CURSOR=false
PUSH_LLM=false
PUSH_TOOL=false
PUSH_WARP=false
INCLUDE_GPU=false
PUSH_LATEST_ONLY=false
SPECIFIC_VERSION=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --all)
            PUSH_ALL=true
            shift
            ;;
        --base)
            PUSH_ALL=false
            PUSH_BASE=true
            shift
            ;;
        --cursor)
            PUSH_ALL=false
            PUSH_CURSOR=true
            shift
            ;;
        --llm)
            PUSH_ALL=false
            PUSH_LLM=true
            shift
            ;;
        --tool)
            PUSH_ALL=false
            PUSH_TOOL=true
            shift
            ;;
        --warp)
            PUSH_ALL=false
            PUSH_WARP=true
            shift
            ;;
        --gpu)
            INCLUDE_GPU=true
            shift
            ;;
        --latest)
            PUSH_LATEST_ONLY=true
            shift
            ;;
        --version)
            SPECIFIC_VERSION="$2"
            shift 2
            ;;
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

# Check if logged in to Docker Hub by trying to access a private repository
print_status "Checking Docker Hub login status..."
if ! docker pull hello-world:latest >/dev/null 2>&1; then
    print_warning "Docker Hub access failed!"
    print_status "Please login first: docker login"
    exit 1
fi
print_success "Docker Hub access confirmed"

# Function to get image tags
get_image_tags() {
    local image_name=$1
    if [[ -n "$SPECIFIC_VERSION" ]]; then
        echo "$SPECIFIC_VERSION"
    elif [[ "$PUSH_LATEST_ONLY" == true ]]; then
        echo "latest"
    else
        docker images "$image_name" --format "{{.Tag}}" | grep -v "<none>"
    fi
}

# Function to push image
push_image() {
    local local_image=$1
    local remote_image=$2
    local tag=$3
    
    local full_local_image="$local_image:$tag"
    local full_remote_image="$remote_image:$tag"
    
    # Check if local image exists
    if ! docker images "$full_local_image" | grep -q "$local_image"; then
        print_warning "Local image $full_local_image not found, skipping..."
        return 1
    fi
    
    print_status "Pushing $full_local_image to $full_remote_image..."
    
    if [[ "$DRY_RUN" == true ]]; then
        print_status "[DRY RUN] Would push: $full_local_image -> $full_remote_image"
        return 0
    fi
    
    # Tag the image
    if docker tag "$full_local_image" "$full_remote_image"; then
        print_success "Tagged $full_local_image as $full_remote_image"
    else
        print_error "Failed to tag $full_local_image"
        return 1
    fi
    
    # Push the image
    if docker push "$full_remote_image"; then
        print_success "Successfully pushed $full_remote_image"
        
        # Remove the remote tag
        docker rmi "$full_remote_image" >/dev/null 2>&1 || true
    else
        print_error "Failed to push $full_remote_image"
        return 1
    fi
}

# Function to push container images
push_container_images() {
    local container_name=$1
    local image_name=$2
    local remote_name=$3
    
    print_status "Processing $container_name..."
    
    if [[ ! -d "$container_name" ]]; then
        print_warning "Container directory $container_name not found, skipping..."
        return 1
    fi
    
    cd "$container_name"
    
    # Get image tags
    TAGS=$(get_image_tags "$image_name")
    
    if [[ -z "$TAGS" ]]; then
        print_warning "No tags found for $image_name"
        cd ..
        return 1
    fi
    
    SUCCESS_COUNT=0
    TOTAL_COUNT=0
    
    for tag in $TAGS; do
        TOTAL_COUNT=$((TOTAL_COUNT + 1))
        if push_image "$image_name" "$DOCKER_HUB_REGISTRY/$DOCKER_HUB_USERNAME/$remote_name" "$tag"; then
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        fi
    done
    
    # Push GPU version if requested
    if [[ "$INCLUDE_GPU" == true ]]; then
        GPU_IMAGE_NAME="${image_name}-gpu"
        if docker images "$GPU_IMAGE_NAME" | grep -q "$GPU_IMAGE_NAME"; then
            print_status "Processing GPU version of $container_name..."
            
            GPU_TAGS=$(get_image_tags "$GPU_IMAGE_NAME")
            for tag in $GPU_TAGS; do
                TOTAL_COUNT=$((TOTAL_COUNT + 1))
                if push_image "$GPU_IMAGE_NAME" "$DOCKER_HUB_REGISTRY/$DOCKER_HUB_USERNAME/${remote_name}-gpu" "$tag"; then
                    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
                fi
            done
        else
            print_warning "GPU version of $image_name not found"
        fi
    fi
    
    cd ..
    
    print_status "$container_name: $SUCCESS_COUNT/$TOTAL_COUNT images pushed successfully"
    
    if [[ $SUCCESS_COUNT -eq $TOTAL_COUNT ]]; then
        print_success "$container_name completed successfully!"
    else
        print_warning "$container_name had some failures"
    fi
}

# Main execution
print_status "Starting VNC Lab image push to Docker Hub..."

if [[ "$DRY_RUN" == true ]]; then
    print_status "DRY RUN MODE - No images will actually be pushed"
fi

print_status "Target registry: $DOCKER_HUB_REGISTRY/$DOCKER_HUB_USERNAME"

# Push base image
if [[ "$PUSH_ALL" == true ]] || [[ "$PUSH_BASE" == true ]]; then
    push_container_images "novnc_base" "vnc-base" "vnc-base"
fi

# Push Cursor IDE images
if [[ "$PUSH_ALL" == true ]] || [[ "$PUSH_CURSOR" == true ]]; then
    push_container_images "novnc_cursor" "vnc-cursor" "vnc-cursor"
fi

# Push LLM CLI image
if [[ "$PUSH_ALL" == true ]] || [[ "$PUSH_LLM" == true ]]; then
    push_container_images "novnc_llm_cli" "vnc-llm-cli" "vnc-llm-cli"
fi

# Push tool image
if [[ "$PUSH_ALL" == true ]] || [[ "$PUSH_TOOL" == true ]]; then
    push_container_images "novnc_tool" "vnc-tool" "vnc-tool"
fi

# Push Warp images
if [[ "$PUSH_ALL" == true ]] || [[ "$PUSH_WARP" == true ]]; then
    push_container_images "novnc_warp" "vnc-warp" "vnc-warp"
fi

print_success "VNC Lab image push completed!"

# Show summary
echo
print_status "Push Summary:"
print_status "  Registry: $DOCKER_HUB_REGISTRY/$DOCKER_HUB_USERNAME"
if [[ "$INCLUDE_GPU" == true ]]; then
    print_status "  GPU versions: Included"
else
    print_status "  GPU versions: Excluded"
fi
if [[ "$PUSH_LATEST_ONLY" == true ]]; then
    print_status "  Tags: Latest only"
elif [[ -n "$SPECIFIC_VERSION" ]]; then
    print_status "  Tags: Version $SPECIFIC_VERSION only"
else
    print_status "  Tags: All available"
fi
if [[ "$DRY_RUN" == true ]]; then
    print_status "  Mode: Dry run (no actual push)"
fi

print_status ""
print_status "Images are now available at:"
print_status "  https://hub.docker.com/r/$DOCKER_HUB_USERNAME" 