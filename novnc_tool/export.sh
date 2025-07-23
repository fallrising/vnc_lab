#!/bin/bash

# VNC Lab - novnc_base Export Script
# Export Docker image to tar file

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
DEFAULT_OUTPUT_DIR="./exports"

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
    echo "  -t, --tag TAG           Image tag to export (default: $DEFAULT_TAG)"
    echo "  -o, --output DIR        Output directory (default: $DEFAULT_OUTPUT_DIR)"
    echo "  -f, --filename NAME     Output filename (auto-generated if not specified)"
    echo "  --compress              Compress the tar file with gzip"
    echo "  --all-tags              Export all tags"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                      # Export latest tag"
    echo "  $0 -t v1.0.0           # Export specific tag"
    echo "  $0 -o /path/to/exports # Export to specific directory"
    echo "  $0 --compress           # Export compressed tar.gz file"
    echo "  $0 --all-tags           # Export all available tags"
}

# Parse command line arguments
TAG=$DEFAULT_TAG
OUTPUT_DIR=$DEFAULT_OUTPUT_DIR
FILENAME=""
COMPRESS=false
EXPORT_ALL_TAGS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--tag)
            TAG="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -f|--filename)
            FILENAME="$2"
            shift 2
            ;;
        --compress)
            COMPRESS=true
            shift
            ;;
        --all-tags)
            EXPORT_ALL_TAGS=true
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

# Create output directory if it doesn't exist
if [[ ! -d "$OUTPUT_DIR" ]]; then
    print_status "Creating output directory: $OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR"
fi

# Function to export single tag
export_tag() {
    local tag=$1
    local local_image="$IMAGE_NAME:$tag"
    
    # Check if local image exists
    if ! docker images "$local_image" | grep -q "$IMAGE_NAME"; then
        print_warning "Local image $local_image not found!"
        return 1
    fi
    
    # Generate filename if not specified
    local output_filename=""
    if [[ -n "$FILENAME" ]]; then
        output_filename="$FILENAME"
    else
        local timestamp=$(date +"%Y%m%d_%H%M%S")
        output_filename="${IMAGE_NAME}_${tag}_${timestamp}"
    fi
    
    # Add compression extension if needed
    if [[ "$COMPRESS" == true ]]; then
        output_filename="${output_filename}.tar.gz"
    else
        output_filename="${output_filename}.tar"
    fi
    
    local output_path="$OUTPUT_DIR/$output_filename"
    
    # Export the image
    print_status "Exporting $local_image to $output_path..."
    
    if [[ "$COMPRESS" == true ]]; then
        if docker save "$local_image" | gzip > "$output_path"; then
            print_success "Successfully exported $local_image to $output_path"
        else
            print_error "Failed to export $local_image"
            return 1
        fi
    else
        if docker save "$local_image" -o "$output_path"; then
            print_success "Successfully exported $local_image to $output_path"
        else
            print_error "Failed to export $local_image"
            return 1
        fi
    fi
    
    # Show file size
    local file_size=$(du -h "$output_path" | cut -f1)
    print_status "File size: $file_size"
    
    return 0
}

# Export images
if [[ "$EXPORT_ALL_TAGS" == true ]]; then
    print_status "Exporting all available tags..."
    
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
        if export_tag "$tag"; then
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        fi
    done
    
    print_status "Export completed: $SUCCESS_COUNT/$TOTAL_COUNT tags exported successfully"
    
    if [[ $SUCCESS_COUNT -eq $TOTAL_COUNT ]]; then
        print_success "All tags exported successfully!"
    else
        print_warning "Some tags failed to export"
        exit 1
    fi
else
    # Export single tag
    if export_tag "$TAG"; then
        print_success "Export completed successfully!"
    else
        print_error "Export failed!"
        exit 1
    fi
fi

# Show exported files
print_status "Exported files in $OUTPUT_DIR:"
ls -lh "$OUTPUT_DIR"/*.tar* 2>/dev/null || print_warning "No exported files found" 