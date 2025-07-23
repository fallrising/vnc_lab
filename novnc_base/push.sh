#!/bin/bash

# VNC Lab - novnc_base Push Script
# Push Docker image to Docker Hub

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="vnc-base"
DEFAULT_TAG="latest"
DEFAULT_REGISTRY="your-dockerhub-username"

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
    echo "  -t, --tag TAG           Image tag to push (default: $DEFAULT_TAG)"
    echo "  -r, --registry REGISTRY Docker Hub registry (default: $DEFAULT_REGISTRY)"
    echo "  --all-tags              Push all tags"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                      # Push latest tag"
    echo "  $0 -t v1.0.0           # Push specific tag"
    echo "  $0 -r myusername       # Push to specific registry"
    echo "  $0 --all-tags          # Push all available tags"
}

# Parse command line arguments
TAG=$DEFAULT_TAG
REGISTRY=$DEFAULT_REGISTRY
PUSH_ALL_TAGS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--tag)
            TAG="$2"
            shift 2
            ;;
        -r|--registry)
            REGISTRY="$2"
            shift 2
            ;;
        --all-tags)
            PUSH_ALL_TAGS=true
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

# Check if user is logged in to Docker Hub
if ! docker info | grep -q "Username"; then
    print_warning "You are not logged in to Docker Hub!"
    print_status "Please run: docker login"
    exit 1
fi

# Function to push single tag
push_tag() {
    local tag=$1
    local local_image="$IMAGE_NAME:$tag"
    local remote_image="$REGISTRY/$IMAGE_NAME:$tag"
    
    # Check if local image exists
    if ! docker images "$local_image" | grep -q "$IMAGE_NAME"; then
        print_warning "Local image $local_image not found!"
        return 1
    fi
    
    # Tag the image for remote registry
    print_status "Tagging $local_image as $remote_image..."
    if ! docker tag "$local_image" "$remote_image"; then
        print_error "Failed to tag image!"
        return 1
    fi
    
    # Push the image
    print_status "Pushing $remote_image..."
    if docker push "$remote_image"; then
        print_success "Successfully pushed $remote_image"
        return 0
    else
        print_error "Failed to push $remote_image"
        return 1
    fi
}

# Push images
if [[ "$PUSH_ALL_TAGS" == true ]]; then
    print_status "Pushing all available tags..."
    
    # Get all tags for the image
    TAGS=$(docker images "$IMAGE_NAME" --format "{{.Tag}}" | grep -v "<none>")
    
    if [[ -z "$TAGS" ]]; then
        print_warning "No tags found for image $IMAGE_NAME"
        print_status "Available images:"
        docker images "$IMAGE_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
        exit 1
    fi
    
    SUCCESS_COUNT=0
    TOTAL_COUNT=0
    
    for tag in $TAGS; do
        TOTAL_COUNT=$((TOTAL_COUNT + 1))
        if push_tag "$tag"; then
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        fi
    done
    
    print_status "Push completed: $SUCCESS_COUNT/$TOTAL_COUNT tags pushed successfully"
    
    if [[ $SUCCESS_COUNT -eq $TOTAL_COUNT ]]; then
        print_success "All tags pushed successfully!"
    else
        print_warning "Some tags failed to push"
        exit 1
    fi
else
    # Push single tag
    if push_tag "$TAG"; then
        print_success "Push completed successfully!"
    else
        print_error "Push failed!"
        exit 1
    fi
fi

# Show pushed images
print_status "Pushed images:"
docker images "$REGISTRY/$IMAGE_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" 