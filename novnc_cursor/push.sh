#!/bin/bash

# VNC Lab - novnc_cursor Push Script
# Push Docker images to registry for Cursor IDE VNC environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="vnc-cursor"
GPU_IMAGE_NAME="vnc-cursor-gpu"
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
    echo "  -r, --registry REGISTRY Registry URL (e.g., docker.io/username)"
    echo "  -t, --tag TAG           Image tag (default: $DEFAULT_TAG)"
    echo "  --gpu                   Push GPU version"
    echo "  --all                   Push both CPU and GPU versions"
    echo "  --latest                Also push as latest tag"
    echo "  --version VERSION       Push with version tag"
    echo "  --dry-run               Show what would be pushed without doing it"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -r docker.io/myuser  # Push to Docker Hub"
    echo "  $0 --gpu -r myregistry.com # Push GPU version"
    echo "  $0 --all -r myregistry.com # Push both versions"
    echo "  $0 --version v1.0.0 -r myregistry.com # Push with version"
    echo "  $0 --dry-run -r myregistry.com # Preview push"
}

# Function to push image
push_image() {
    local image_name=$1
    local tag=$2
    local registry=$3
    local dry_run=$4
    
    local full_image_name="$image_name:$tag"
    local registry_image_name="$registry/$image_name:$tag"
    
    print_status "Processing image: $full_image_name"
    
    # Check if image exists
    if ! docker images "$full_image_name" | grep -q "$image_name"; then
        print_warning "Image $full_image_name not found, skipping..."
        return 1
    fi
    
    if [[ "$dry_run" == true ]]; then
        print_status "DRY RUN: Would tag $full_image_name as $registry_image_name"
        print_status "DRY RUN: Would push $registry_image_name"
        return 0
    fi
    
    # Tag image for registry
    print_status "Tagging image for registry..."
    if docker tag "$full_image_name" "$registry_image_name"; then
        print_success "Tagged as: $registry_image_name"
    else
        print_error "Failed to tag image"
        return 1
    fi
    
    # Push image
    print_status "Pushing image to registry..."
    if docker push "$registry_image_name"; then
        print_success "Pushed: $registry_image_name"
        
        # Remove local tag
        docker rmi "$registry_image_name" >/dev/null 2>&1 || true
        
        return 0
    else
        print_error "Failed to push image: $registry_image_name"
        # Clean up local tag
        docker rmi "$registry_image_name" >/dev/null 2>&1 || true
        return 1
    fi
}

# Function to push with multiple tags
push_with_tags() {
    local image_name=$1
    local base_tag=$2
    local registry=$3
    local version_tag=$4
    local push_latest=$5
    local dry_run=$6
    
    local tags=("$base_tag")
    
    # Add version tag if specified
    if [[ -n "$version_tag" ]]; then
        tags+=("$version_tag")
    fi
    
    # Add latest tag if requested
    if [[ "$push_latest" == true ]]; then
        tags+=("latest")
    fi
    
    for tag in "${tags[@]}"; do
        push_image "$image_name" "$base_tag" "$registry" "$dry_run"
    done
}

# Parse command line arguments
REGISTRY=$DEFAULT_REGISTRY
TAG=$DEFAULT_TAG
USE_GPU=false
PUSH_ALL=false
PUSH_LATEST=false
VERSION_TAG=""
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
        --version)
            VERSION_TAG="$2"
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

# Check if registry is specified
if [[ -z "$REGISTRY" ]]; then
    print_error "Registry must be specified with -r/--registry"
    print_status "Example: $0 -r docker.io/myusername"
    exit 1
fi

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running or not accessible!"
    exit 1
fi

# Check if logged in to registry
if [[ "$DRY_RUN" != true ]]; then
    print_status "Checking registry authentication..."
    if ! docker info | grep -q "Username"; then
        print_warning "Not logged in to Docker registry"
        print_status "Please run: docker login $REGISTRY"
        exit 1
    fi
fi

print_status "Starting push process..."
print_status "Registry: $REGISTRY"
print_status "Base tag: $TAG"
if [[ -n "$VERSION_TAG" ]]; then
    print_status "Version tag: $VERSION_TAG"
fi
if [[ "$PUSH_LATEST" == true ]]; then
    print_status "Will also push as latest"
fi
if [[ "$DRY_RUN" == true ]]; then
    print_status "DRY RUN MODE - No actual push will occur"
fi

# Push images
if [[ "$PUSH_ALL" == true ]]; then
    print_status "Pushing both CPU and GPU versions..."
    
    # Push CPU version
    push_with_tags "$IMAGE_NAME" "$TAG" "$REGISTRY" "$VERSION_TAG" "$PUSH_LATEST" "$DRY_RUN"
    
    # Push GPU version
    push_with_tags "$GPU_IMAGE_NAME" "$TAG" "$REGISTRY" "$VERSION_TAG" "$PUSH_LATEST" "$DRY_RUN"
    
elif [[ "$USE_GPU" == true ]]; then
    print_status "Pushing GPU version..."
    push_with_tags "$GPU_IMAGE_NAME" "$TAG" "$REGISTRY" "$VERSION_TAG" "$PUSH_LATEST" "$DRY_RUN"
else
    print_status "Pushing CPU version..."
    push_with_tags "$IMAGE_NAME" "$TAG" "$REGISTRY" "$VERSION_TAG" "$PUSH_LATEST" "$DRY_RUN"
fi

if [[ "$DRY_RUN" == true ]]; then
    print_success "Dry run completed!"
    print_status "Run without --dry-run to actually push images"
else
    print_success "Push completed!"
    print_status "Images are now available at:"
    if [[ "$PUSH_ALL" == true ]]; then
        echo "  - $REGISTRY/$IMAGE_NAME:$TAG"
        echo "  - $REGISTRY/$GPU_IMAGE_NAME:$TAG"
        if [[ -n "$VERSION_TAG" ]]; then
            echo "  - $REGISTRY/$IMAGE_NAME:$VERSION_TAG"
            echo "  - $REGISTRY/$GPU_IMAGE_NAME:$VERSION_TAG"
        fi
        if [[ "$PUSH_LATEST" == true ]]; then
            echo "  - $REGISTRY/$IMAGE_NAME:latest"
            echo "  - $REGISTRY/$GPU_IMAGE_NAME:latest"
        fi
    elif [[ "$USE_GPU" == true ]]; then
        echo "  - $REGISTRY/$GPU_IMAGE_NAME:$TAG"
        if [[ -n "$VERSION_TAG" ]]; then
            echo "  - $REGISTRY/$GPU_IMAGE_NAME:$VERSION_TAG"
        fi
        if [[ "$PUSH_LATEST" == true ]]; then
            echo "  - $REGISTRY/$GPU_IMAGE_NAME:latest"
        fi
    else
        echo "  - $REGISTRY/$IMAGE_NAME:$TAG"
        if [[ -n "$VERSION_TAG" ]]; then
            echo "  - $REGISTRY/$IMAGE_NAME:$VERSION_TAG"
        fi
        if [[ "$PUSH_LATEST" == true ]]; then
            echo "  - $REGISTRY/$IMAGE_NAME:latest"
        fi
    fi
fi 