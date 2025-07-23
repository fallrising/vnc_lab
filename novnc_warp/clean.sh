#!/bin/bash

# VNC Lab - novnc_warp Clean Script
# Clean Docker containers and images for Warp terminal VNC environment

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
CONTAINER_NAME="vnc-warp-container"

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
    echo "  -a, --all              Clean everything (containers, images, volumes)"
    echo "  -c, --containers       Clean containers only"
    echo "  -i, --images           Clean images only"
    echo "  -v, --volumes          Clean volumes only"
    echo "  --gpu                  Clean GPU version"
    echo "  -f, --force            Force clean without confirmation"
    echo "  -h, --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                     # Interactive clean"
    echo "  $0 -a                  # Clean everything"
    echo "  $0 -c -f               # Force clean containers"
    echo "  $0 --gpu -i            # Clean GPU images"
}

# Function to clean containers
clean_containers() {
    local force=$1
    local containers=()
    
    # Find containers
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            containers+=("$line")
        fi
    done < <(docker ps -a --format "{{.Names}}" | grep -E "(vnc-warp|$CONTAINER_NAME)")
    
    if [[ ${#containers[@]} -eq 0 ]]; then
        print_status "No containers to clean"
        return
    fi
    
    print_status "Found containers to clean:"
    for container in "${containers[@]}"; do
        echo "  - $container"
    done
    
    if [[ "$force" != true ]]; then
        read -p "Do you want to remove these containers? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Container cleanup cancelled"
            return
        fi
    fi
    
    for container in "${containers[@]}"; do
        print_status "Removing container: $container"
        if docker rm -f "$container" >/dev/null 2>&1; then
            print_success "Removed container: $container"
        else
            print_error "Failed to remove container: $container"
        fi
    done
}

# Function to clean images
clean_images() {
    local force=$1
    local gpu=$2
    local images=()
    
    # Find images
    if [[ "$gpu" == true ]]; then
        while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                images+=("$line")
            fi
        done < <(docker images --format "{{.Repository}}:{{.Tag}}" | grep "$GPU_IMAGE_NAME")
    else
        while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                images+=("$line")
            fi
        done < <(docker images --format "{{.Repository}}:{{.Tag}}" | grep "$IMAGE_NAME")
    fi
    
    if [[ ${#images[@]} -eq 0 ]]; then
        print_status "No images to clean"
        return
    fi
    
    print_status "Found images to clean:"
    for image in "${images[@]}"; do
        echo "  - $image"
    done
    
    if [[ "$force" != true ]]; then
        read -p "Do you want to remove these images? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Image cleanup cancelled"
            return
        fi
    fi
    
    for image in "${images[@]}"; do
        print_status "Removing image: $image"
        if docker rmi -f "$image" >/dev/null 2>&1; then
            print_success "Removed image: $image"
        else
            print_error "Failed to remove image: $image"
        fi
    done
}

# Function to clean volumes
clean_volumes() {
    local force=$1
    local volumes=()
    
    # Find volumes
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            volumes+=("$line")
        fi
    done < <(docker volume ls --format "{{.Name}}" | grep -E "(warp|vnc)")
    
    if [[ ${#volumes[@]} -eq 0 ]]; then
        print_status "No volumes to clean"
        return
    fi
    
    print_status "Found volumes to clean:"
    for volume in "${volumes[@]}"; do
        echo "  - $volume"
    done
    
    if [[ "$force" != true ]]; then
        read -p "Do you want to remove these volumes? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Volume cleanup cancelled"
            return
        fi
    fi
    
    for volume in "${volumes[@]}"; do
        print_status "Removing volume: $volume"
        if docker volume rm "$volume" >/dev/null 2>&1; then
            print_success "Removed volume: $volume"
        else
            print_error "Failed to remove volume: $volume"
        fi
    done
}

# Parse command line arguments
CLEAN_ALL=false
CLEAN_CONTAINERS=false
CLEAN_IMAGES=false
CLEAN_VOLUMES=false
USE_GPU=false
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--all)
            CLEAN_ALL=true
            shift
            ;;
        -c|--containers)
            CLEAN_CONTAINERS=true
            shift
            ;;
        -i|--images)
            CLEAN_IMAGES=true
            shift
            ;;
        -v|--volumes)
            CLEAN_VOLUMES=true
            shift
            ;;
        --gpu)
            USE_GPU=true
            shift
            ;;
        -f|--force)
            FORCE=true
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

# If no specific option is provided, clean all
if [[ "$CLEAN_ALL" == false && "$CLEAN_CONTAINERS" == false && "$CLEAN_IMAGES" == false && "$CLEAN_VOLUMES" == false ]]; then
    CLEAN_ALL=true
fi

print_status "Starting cleanup process..."

# Clean containers
if [[ "$CLEAN_ALL" == true || "$CLEAN_CONTAINERS" == true ]]; then
    print_status "Cleaning containers..."
    clean_containers "$FORCE"
fi

# Clean images
if [[ "$CLEAN_ALL" == true || "$CLEAN_IMAGES" == true ]]; then
    print_status "Cleaning images..."
    clean_images "$FORCE" "$USE_GPU"
fi

# Clean volumes
if [[ "$CLEAN_ALL" == true || "$CLEAN_VOLUMES" == true ]]; then
    print_status "Cleaning volumes..."
    clean_volumes "$FORCE"
fi

print_success "Cleanup completed!" 