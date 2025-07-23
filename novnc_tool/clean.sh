#!/bin/bash

# VNC Lab - novnc_base Clean Script
# Clean up containers and images

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="vnc-tool"
CONTAINER_NAME_PREFIX="vnc-tool"

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
    echo "  --containers            Clean containers only"
    echo "  --images                Clean images only"
    echo "  --volumes               Clean volumes only"
    echo "  --all                   Clean everything (default)"
    echo "  --force                 Force cleanup without confirmation"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                      # Clean everything with confirmation"
    echo "  $0 --force              # Clean everything without confirmation"
    echo "  $0 --containers         # Clean containers only"
    echo "  $0 --images --force     # Clean images without confirmation"
}

# Parse command line arguments
CLEAN_CONTAINERS=false
CLEAN_IMAGES=false
CLEAN_VOLUMES=false
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --containers)
            CLEAN_CONTAINERS=true
            shift
            ;;
        --images)
            CLEAN_IMAGES=true
            shift
            ;;
        --volumes)
            CLEAN_VOLUMES=true
            shift
            ;;
        --all)
            CLEAN_CONTAINERS=true
            CLEAN_IMAGES=true
            CLEAN_VOLUMES=true
            shift
            ;;
        --force)
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

# If no specific option is provided, clean everything
if [[ "$CLEAN_CONTAINERS" == false ]] && [[ "$CLEAN_IMAGES" == false ]] && [[ "$CLEAN_VOLUMES" == false ]]; then
    CLEAN_CONTAINERS=true
    CLEAN_IMAGES=true
    CLEAN_VOLUMES=true
fi

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running or not accessible!"
    exit 1
fi

# Function to confirm action
confirm_action() {
    local message=$1
    if [[ "$FORCE" == false ]]; then
        echo -e "${YELLOW}$message${NC}"
        read -p "Do you want to continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Operation cancelled"
            exit 0
        fi
    fi
}

# Function to clean containers
clean_containers() {
    print_status "Cleaning containers..."
    
    # Find containers with the prefix
    CONTAINERS=$(docker ps -a --filter "name=$CONTAINER_NAME_PREFIX" --format "{{.Names}}")
    
    if [[ -z "$CONTAINERS" ]]; then
        print_status "No containers found with prefix '$CONTAINER_NAME_PREFIX'"
        return 0
    fi
    
    print_status "Found containers:"
    echo "$CONTAINERS"
    
    confirm_action "This will stop and remove the following containers:"
    
    for container in $CONTAINERS; do
        print_status "Stopping container: $container"
        docker stop "$container" >/dev/null 2>&1 || true
        
        print_status "Removing container: $container"
        docker rm "$container" >/dev/null 2>&1 || true
    done
    
    print_success "Containers cleaned successfully!"
}

# Function to clean images
clean_images() {
    print_status "Cleaning images..."
    
    # Find images with the name
    IMAGES=$(docker images "$IMAGE_NAME" --format "{{.Repository}}:{{.Tag}}")
    
    if [[ -z "$IMAGES" ]]; then
        print_status "No images found with name '$IMAGE_NAME'"
        return 0
    fi
    
    print_status "Found images:"
    docker images "$IMAGE_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
    
    confirm_action "This will remove the following images:"
    
    for image in $IMAGES; do
        print_status "Removing image: $image"
        docker rmi "$image" >/dev/null 2>&1 || true
    done
    
    print_success "Images cleaned successfully!"
}

# Function to clean volumes
clean_volumes() {
    print_status "Cleaning volumes..."
    
    # Find volumes with the prefix
    VOLUMES=$(docker volume ls --filter "name=$CONTAINER_NAME_PREFIX" --format "{{.Name}}")
    
    if [[ -z "$VOLUMES" ]]; then
        print_status "No volumes found with prefix '$CONTAINER_NAME_PREFIX'"
        return 0
    fi
    
    print_status "Found volumes:"
    echo "$VOLUMES"
    
    confirm_action "This will remove the following volumes:"
    
    for volume in $VOLUMES; do
        print_status "Removing volume: $volume"
        docker volume rm "$volume" >/dev/null 2>&1 || true
    done
    
    print_success "Volumes cleaned successfully!"
}

# Function to clean dangling resources
clean_dangling() {
    print_status "Cleaning dangling resources..."
    
    # Clean dangling images
    DANGLING_IMAGES=$(docker images -f "dangling=true" -q)
    if [[ -n "$DANGLING_IMAGES" ]]; then
        print_status "Removing dangling images..."
        docker rmi "$DANGLING_IMAGES" >/dev/null 2>&1 || true
    fi
    
    # Clean dangling volumes
    DANGLING_VOLUMES=$(docker volume ls -f "dangling=true" -q)
    if [[ -n "$DANGLING_VOLUMES" ]]; then
        print_status "Removing dangling volumes..."
        docker volume rm "$DANGLING_VOLUMES" >/dev/null 2>&1 || true
    fi
    
    print_success "Dangling resources cleaned successfully!"
}

# Perform cleanup
if [[ "$CLEAN_CONTAINERS" == true ]]; then
    clean_containers
fi

if [[ "$CLEAN_IMAGES" == true ]]; then
    clean_images
fi

if [[ "$CLEAN_VOLUMES" == true ]]; then
    clean_volumes
fi

# Clean dangling resources if cleaning everything
if [[ "$CLEAN_CONTAINERS" == true ]] && [[ "$CLEAN_IMAGES" == true ]] && [[ "$CLEAN_VOLUMES" == true ]]; then
    clean_dangling
fi

print_success "Cleanup completed successfully!"

# Show remaining resources
print_status "Remaining resources:"
print_status "Containers:"
docker ps -a --filter "name=$CONTAINER_NAME_PREFIX" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || print_status "No containers found"

print_status "Images:"
docker images "$IMAGE_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" 2>/dev/null || print_status "No images found"

print_status "Volumes:"
docker volume ls --filter "name=$CONTAINER_NAME_PREFIX" --format "table {{.Name}}\t{{.Driver}}" 2>/dev/null || print_status "No volumes found" 