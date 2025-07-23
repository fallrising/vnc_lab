#!/bin/bash

# VNC Lab - novnc_warp Push Script
# Push Docker images to registry for Warp terminal VNC environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="vnc-warp"
GPU_IMAGE_NAME="vnc-warp-gpu"
DEFAULT_TAG="latest"
DEFAULT_REGISTRY=""

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
    echo "  -r, --registry REGISTRY  Docker registry (e.g., docker.io/username)"
    echo "  -t, --tag TAG            Image tag (default: $DEFAULT_TAG)"
    echo "  --gpu                    Push GPU version"
    echo "  --all                    Push both CPU and GPU versions"
    echo "  --latest                 Also push as latest tag"
    echo "  --force                  Force push without confirmation"
    echo "  --dry-run                Show what would be pushed without actually pushing"
    echo "  -h, --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -r docker.io/myuser   # Push CPU version to registry"
    echo "  $0 --gpu -r myregistry   # Push GPU version"
    echo "  $0 --all -r myregistry   # Push both versions"
    echo "  $0 --latest -r myregistry # Push with latest tag"
    echo "  $0 --dry-run -r myregistry # Preview push operations"
}

# Function to check if image exists
check_image_exists() {
    local image_name=$1
    local tag=$2
    
    if docker images "$image_name:$tag" | grep -q "$image_name"; then
        return 0
    else
        return 1
    fi
}

# Function to push image
push_image() {
    local source_image=$1
    local target_image=$2
    local dry_run=$3
    
    print_status "Pushing: $source_image -> $target_image"
    
    if [[ "$dry_run" == true ]]; then
        print_status "[DRY RUN] Would push: $source_image -> $target_image"
        return 0
    fi
    
    # Tag the image
    if docker tag "$source_image" "$target_image"; then
        print_success "Tagged: $source_image -> $target_image"
    else
        print_error "Failed to tag image: $source_image"
        return 1
    fi
    
    # Push the image
    if docker push "$target_image"; then
        print_success "Pushed: $target_image"
        return 0
    else
        print_error "Failed to push image: $target_image"
        return 1
    fi
}

# Parse command line arguments
REGISTRY=""
TAG=$DEFAULT_TAG
USE_GPU=false
PUSH_ALL=false
PUSH_LATEST=false
FORCE=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--registry)
            REGISTRY="$2"
            shift 2
            ;;
        -t|--tag)
            TAG="$2"
            shift 2
            ;;
        --gpu)
            USE_GPU=true
            shift
            ;;
        --all)
            PUSH_ALL=true
            shift
            ;;
        --latest)
            PUSH_LATEST=true
            shift
            ;;
        --force)
            FORCE=true
            shift
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

# Check if registry is provided
if [[ -z "$REGISTRY" ]]; then
    print_error "Registry is required. Use -r or --registry option."
    show_usage
    exit 1
fi

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running or not accessible!"
    exit 1
fi

# Check if user is logged in to registry
if [[ "$DRY_RUN" != true ]]; then
    if ! docker info | grep -q "Username"; then
        print_warning "You may not be logged in to the registry."
        print_status "Use 'docker login $REGISTRY' to authenticate."
        if [[ "$FORCE" != true ]]; then
            read -p "Continue anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_status "Push cancelled"
                exit 1
            fi
        fi
    fi
fi

print_status "Starting push process..."
print_status "Registry: $REGISTRY"
print_status "Tag: $TAG"

# Determine which images to push
IMAGES_TO_PUSH=()

if [[ "$PUSH_ALL" == true ]]; then
    # Push both CPU and GPU versions
    if check_image_exists "$IMAGE_NAME" "$TAG"; then
        IMAGES_TO_PUSH+=("$IMAGE_NAME:$TAG")
    else
        print_warning "CPU image $IMAGE_NAME:$TAG not found"
    fi
    
    if check_image_exists "$GPU_IMAGE_NAME" "$TAG"; then
        IMAGES_TO_PUSH+=("$GPU_IMAGE_NAME:$TAG")
    else
        print_warning "GPU image $GPU_IMAGE_NAME:$TAG not found"
    fi
elif [[ "$USE_GPU" == true ]]; then
    # Push GPU version only
    if check_image_exists "$GPU_IMAGE_NAME" "$TAG"; then
        IMAGES_TO_PUSH+=("$GPU_IMAGE_NAME:$TAG")
    else
        print_error "GPU image $GPU_IMAGE_NAME:$TAG not found!"
        print_status "You can build it using: ./build.sh --gpu"
        exit 1
    fi
else
    # Push CPU version only
    if check_image_exists "$IMAGE_NAME" "$TAG"; then
        IMAGES_TO_PUSH+=("$IMAGE_NAME:$TAG")
    else
        print_error "CPU image $IMAGE_NAME:$TAG not found!"
        print_status "You can build it using: ./build.sh"
        exit 1
    fi
fi

if [[ ${#IMAGES_TO_PUSH[@]} -eq 0 ]]; then
    print_error "No images found to push!"
    exit 1
fi

# Show what will be pushed
print_status "Images to push:"
for image in "${IMAGES_TO_PUSH[@]}"; do
    echo "  - $image -> $REGISTRY/$image"
    if [[ "$PUSH_LATEST" == true ]]; then
        echo "  - $image -> $REGISTRY/${image%:*}:latest"
    fi
done

# Confirm push
if [[ "$FORCE" != true && "$DRY_RUN" != true ]]; then
    read -p "Do you want to push these images? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Push cancelled"
        exit 1
    fi
fi

# Push images
SUCCESS_COUNT=0
TOTAL_COUNT=0

for image in "${IMAGES_TO_PUSH[@]}"; do
    local_image_name=$(echo "$image" | cut -d: -f1)
    local_tag=$(echo "$image" | cut -d: -f2)
    
    # Push with specified tag
    target_image="$REGISTRY/$local_image_name:$local_tag"
    TOTAL_COUNT=$((TOTAL_COUNT + 1))
    
    if push_image "$image" "$target_image" "$DRY_RUN"; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    fi
    
    # Push as latest if requested
    if [[ "$PUSH_LATEST" == true ]]; then
        target_latest="$REGISTRY/$local_image_name:latest"
        TOTAL_COUNT=$((TOTAL_COUNT + 1))
        
        if push_image "$image" "$target_latest" "$DRY_RUN"; then
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        fi
    fi
done

# Summary
if [[ "$DRY_RUN" == true ]]; then
    print_success "Dry run completed. $TOTAL_COUNT operations would be performed."
else
    if [[ $SUCCESS_COUNT -eq $TOTAL_COUNT ]]; then
        print_success "All images pushed successfully! ($SUCCESS_COUNT/$TOTAL_COUNT)"
    else
        print_warning "Some images failed to push. ($SUCCESS_COUNT/$TOTAL_COUNT)"
        exit 1
    fi
fi

print_status "Push completed!"
print_status "You can now pull the images using:"
for image in "${IMAGES_TO_PUSH[@]}"; do
    local_image_name=$(echo "$image" | cut -d: -f1)
    local_tag=$(echo "$image" | cut -d: -f2)
    echo "  docker pull $REGISTRY/$local_image_name:$local_tag"
done 