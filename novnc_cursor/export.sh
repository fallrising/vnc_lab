#!/bin/bash

# VNC Lab - novnc_cursor Export Script
# Export Docker images and configurations for Cursor IDE VNC environment

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
DEFAULT_EXPORT_DIR="./exports"
DEFAULT_EXPORT_NAME="novnc_cursor_export"

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
    echo "  -d, --dir DIR           Export directory (default: $DEFAULT_EXPORT_DIR)"
    echo "  -n, --name NAME         Export name (default: $DEFAULT_EXPORT_NAME)"
    echo "  --gpu                   Export GPU version"
    echo "  --all                   Export both CPU and GPU versions"
    echo "  --compress              Compress exported files"
    echo "  --include-config        Include configuration files"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                      # Export default CPU version"
    echo "  $0 --gpu               # Export GPU version"
    echo "  $0 --all               # Export both versions"
    echo "  $0 -d /backup -n my_export # Custom directory and name"
    echo "  $0 --compress          # Compress exported files"
}

# Function to export image
export_image() {
    local image_name=$1
    local tag=$2
    local export_dir=$3
    local export_name=$4
    local compress=$5
    
    local full_image_name="$image_name:$tag"
    local export_file="$export_dir/${export_name}_${image_name}_${tag}.tar"
    
    print_status "Exporting image: $full_image_name"
    
    # Check if image exists
    if ! docker images "$full_image_name" | grep -q "$image_name"; then
        print_warning "Image $full_image_name not found, skipping..."
        return 1
    fi
    
    # Create export directory
    mkdir -p "$export_dir"
    
    # Export image
    if docker save -o "$export_file" "$full_image_name"; then
        print_success "Exported image to: $export_file"
        
        # Compress if requested
        if [[ "$compress" == true ]]; then
            print_status "Compressing export file..."
            if gzip "$export_file"; then
                print_success "Compressed to: ${export_file}.gz"
                export_file="${export_file}.gz"
            else
                print_warning "Failed to compress file"
            fi
        fi
        
        # Show file size
        local file_size=$(du -h "$export_file" | cut -f1)
        print_status "Export file size: $file_size"
        
        return 0
    else
        print_error "Failed to export image: $full_image_name"
        return 1
    fi
}

# Function to export configuration
export_config() {
    local export_dir=$1
    local export_name=$2
    local compress=$3
    
    local config_dir="$export_dir/${export_name}_config"
    local config_archive="$export_dir/${export_name}_config.tar"
    
    print_status "Exporting configuration files..."
    
    # Create config directory
    mkdir -p "$config_dir"
    
    # Copy configuration files
    cp -r . "$config_dir/" 2>/dev/null || true
    
    # Remove unnecessary files from config export
    rm -rf "$config_dir/exports" 2>/dev/null || true
    rm -rf "$config_dir/.git" 2>/dev/null || true
    
    # Create config archive
    if tar -cf "$config_archive" -C "$config_dir" .; then
        print_success "Exported configuration to: $config_archive"
        
        # Compress if requested
        if [[ "$compress" == true ]]; then
            print_status "Compressing config archive..."
            if gzip "$config_archive"; then
                print_success "Compressed to: ${config_archive}.gz"
                config_archive="${config_archive}.gz"
            else
                print_warning "Failed to compress config archive"
            fi
        fi
        
        # Clean up temp directory
        rm -rf "$config_dir"
        
        # Show file size
        local file_size=$(du -h "$config_archive" | cut -f1)
        print_status "Config archive size: $file_size"
        
        return 0
    else
        print_error "Failed to export configuration"
        rm -rf "$config_dir"
        return 1
    fi
}

# Parse command line arguments
TAG=$DEFAULT_TAG
EXPORT_DIR=$DEFAULT_EXPORT_DIR
EXPORT_NAME=$DEFAULT_EXPORT_NAME
USE_GPU=false
EXPORT_ALL=false
COMPRESS=false
INCLUDE_CONFIG=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--tag)
            TAG="$2"
            shift 2
            ;;
        -d|--dir)
            EXPORT_DIR="$2"
            shift 2
            ;;
        -n|--name)
            EXPORT_NAME="$2"
            shift 2
            ;;
        --gpu)
            USE_GPU=true
            shift
            ;;
        --all)
            EXPORT_ALL=true
            shift
            ;;
        --compress)
            COMPRESS=true
            shift
            ;;
        --include-config)
            INCLUDE_CONFIG=true
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

# Create export directory
mkdir -p "$EXPORT_DIR"

print_status "Starting export process..."
print_status "Export directory: $EXPORT_DIR"
print_status "Export name: $EXPORT_NAME"

# Export images
if [[ "$EXPORT_ALL" == true ]]; then
    print_status "Exporting both CPU and GPU versions..."
    
    # Export CPU version
    export_image "$IMAGE_NAME" "$TAG" "$EXPORT_DIR" "$EXPORT_NAME" "$COMPRESS"
    
    # Export GPU version
    export_image "$GPU_IMAGE_NAME" "$TAG" "$EXPORT_DIR" "$EXPORT_NAME" "$COMPRESS"
    
elif [[ "$USE_GPU" == true ]]; then
    print_status "Exporting GPU version..."
    export_image "$GPU_IMAGE_NAME" "$TAG" "$EXPORT_DIR" "$EXPORT_NAME" "$COMPRESS"
else
    print_status "Exporting CPU version..."
    export_image "$IMAGE_NAME" "$TAG" "$EXPORT_DIR" "$EXPORT_NAME" "$COMPRESS"
fi

# Export configuration if requested
if [[ "$INCLUDE_CONFIG" == true ]]; then
    export_config "$EXPORT_DIR" "$EXPORT_NAME" "$COMPRESS"
fi

# Create export summary
SUMMARY_FILE="$EXPORT_DIR/${EXPORT_NAME}_summary.txt"
{
    echo "VNC Lab - novnc_cursor Export Summary"
    echo "====================================="
    echo "Export Date: $(date)"
    echo "Export Name: $EXPORT_NAME"
    echo "Export Directory: $EXPORT_DIR"
    echo ""
    echo "Exported Images:"
    if [[ "$EXPORT_ALL" == true ]]; then
        echo "  - $IMAGE_NAME:$TAG"
        echo "  - $GPU_IMAGE_NAME:$TAG"
    elif [[ "$USE_GPU" == true ]]; then
        echo "  - $GPU_IMAGE_NAME:$TAG"
    else
        echo "  - $IMAGE_NAME:$TAG"
    fi
    echo ""
    echo "Configuration:"
    if [[ "$INCLUDE_CONFIG" == true ]]; then
        echo "  - Included configuration files"
    else
        echo "  - Not included (use --include-config to include)"
    fi
    echo ""
    echo "Compression:"
    if [[ "$COMPRESS" == true ]]; then
        echo "  - Files are compressed with gzip"
    else
        echo "  - Files are not compressed"
    fi
    echo ""
    echo "Import Instructions:"
    echo "1. Copy exported files to target system"
    echo "2. Load image: docker load -i <export_file>"
    echo "3. Run container: ./run.sh"
    if [[ "$USE_GPU" == true || "$EXPORT_ALL" == true ]]; then
        echo "4. For GPU version: ./run.sh --gpu"
    fi
} > "$SUMMARY_FILE"

print_success "Export completed!"
print_status "Export summary saved to: $SUMMARY_FILE"
print_status "Export directory: $EXPORT_DIR" 