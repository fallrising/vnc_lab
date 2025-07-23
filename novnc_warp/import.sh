#!/bin/bash

# VNC Lab - novnc_warp Import Script
# Import Docker images and configurations for Warp terminal VNC environment

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
DEFAULT_IMPORT_DIR="./imports"

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
    echo "  -f, --file FILE         Import file path"
    echo "  -d, --dir DIR           Import directory (default: $DEFAULT_IMPORT_DIR)"
    echo "  -t, --tag TAG           Target tag for imported image (default: $DEFAULT_TAG)"
    echo "  --gpu                   Import GPU version"
    echo "  --all                   Import all files from directory"
    echo "  --config                Import configuration files"
    echo "  --overwrite             Overwrite existing images"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -f export.tar        # Import specific file"
    echo "  $0 -d /backup --all     # Import all from directory"
    echo "  $0 --gpu -f gpu.tar     # Import GPU version"
    echo "  $0 --config -d /config  # Import configuration"
}

# Function to import image
import_image() {
    local import_file=$1
    local target_tag=$2
    local overwrite=$3
    
    print_status "Importing image from: $import_file"
    
    # Check if file exists
    if [[ ! -f "$import_file" ]]; then
        print_error "Import file not found: $import_file"
        return 1
    fi
    
    # Check if file is compressed
    local actual_file="$import_file"
    if [[ "$import_file" == *.gz ]]; then
        print_status "Decompressing file..."
        local decompressed_file="${import_file%.gz}"
        if gunzip -c "$import_file" > "$decompressed_file"; then
            actual_file="$decompressed_file"
            print_success "Decompressed to: $actual_file"
        else
            print_error "Failed to decompress file"
            return 1
        fi
    fi
    
    # Check for existing images
    local existing_images=()
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            existing_images+=("$line")
        fi
    done < <(docker images --format "{{.Repository}}:{{.Tag}}" | grep -E "(vnc-warp|vnc-warp-gpu)")
    
    if [[ ${#existing_images[@]} -gt 0 && "$overwrite" != true ]]; then
        print_warning "Found existing images:"
        for img in "${existing_images[@]}"; do
            echo "  - $img"
        done
        read -p "Do you want to overwrite existing images? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Import cancelled"
            return 1
        fi
    fi
    
    # Import image
    if docker load -i "$actual_file"; then
        print_success "Image imported successfully"
        
        # Show imported images
        print_status "Imported images:"
        docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" | grep -E "(vnc-warp|vnc-warp-gpu)"
        
        # Clean up decompressed file if it was created
        if [[ "$actual_file" != "$import_file" ]]; then
            rm -f "$actual_file"
        fi
        
        return 0
    else
        print_error "Failed to import image"
        # Clean up decompressed file if it was created
        if [[ "$actual_file" != "$import_file" ]]; then
            rm -f "$actual_file"
        fi
        return 1
    fi
}

# Function to import configuration
import_config() {
    local config_file=$1
    local overwrite=$2
    
    print_status "Importing configuration from: $config_file"
    
    # Check if file exists
    if [[ ! -f "$config_file" ]]; then
        print_error "Configuration file not found: $config_file"
        return 1
    fi
    
    # Check if file is compressed
    local actual_file="$config_file"
    if [[ "$config_file" == *.gz ]]; then
        print_status "Decompressing configuration file..."
        local decompressed_file="${config_file%.gz}"
        if gunzip -c "$config_file" > "$decompressed_file"; then
            actual_file="$decompressed_file"
            print_success "Decompressed to: $actual_file"
        else
            print_error "Failed to decompress configuration file"
            return 1
        fi
    fi
    
    # Check for existing configuration
    if [[ -f "Dockerfile" && "$overwrite" != true ]]; then
        print_warning "Configuration files already exist in current directory"
        read -p "Do you want to overwrite existing configuration? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Configuration import cancelled"
            return 1
        fi
    fi
    
    # Create backup of existing files
    if [[ -f "Dockerfile" ]]; then
        local backup_dir="backup_$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$backup_dir"
        cp -r . "$backup_dir/" 2>/dev/null || true
        print_status "Backup created in: $backup_dir"
    fi
    
    # Extract configuration
    if tar -xf "$actual_file"; then
        print_success "Configuration imported successfully"
        
        # Clean up decompressed file if it was created
        if [[ "$actual_file" != "$config_file" ]]; then
            rm -f "$actual_file"
        fi
        
        return 0
    else
        print_error "Failed to import configuration"
        # Clean up decompressed file if it was created
        if [[ "$actual_file" != "$config_file" ]]; then
            rm -f "$actual_file"
        fi
        return 1
    fi
}

# Function to find import files
find_import_files() {
    local import_dir=$1
    local gpu=$2
    local files=()
    
    if [[ "$gpu" == true ]]; then
        # Find GPU version files
        while IFS= read -r file; do
            if [[ -f "$file" ]]; then
                files+=("$file")
            fi
        done < <(find "$import_dir" -name "*gpu*" -type f \( -name "*.tar" -o -name "*.tar.gz" \) 2>/dev/null)
    else
        # Find CPU version files (exclude GPU files)
        while IFS= read -r file; do
            if [[ -f "$file" && ! "$file" =~ gpu ]]; then
                files+=("$file")
            fi
        done < <(find "$import_dir" -name "*.tar" -o -name "*.tar.gz" 2>/dev/null)
    fi
    
    echo "${files[@]}"
}

# Parse command line arguments
IMPORT_FILE=""
IMPORT_DIR=$DEFAULT_IMPORT_DIR
TARGET_TAG=$DEFAULT_TAG
USE_GPU=false
IMPORT_ALL=false
IMPORT_CONFIG=false
OVERWRITE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            IMPORT_FILE="$2"
            shift 2
            ;;
        -d|--dir)
            IMPORT_DIR="$2"
            shift 2
            ;;
        -t|--tag)
            TARGET_TAG="$2"
            shift 2
            ;;
        --gpu)
            USE_GPU=true
            shift
            ;;
        --all)
            IMPORT_ALL=true
            shift
            ;;
        --config)
            IMPORT_CONFIG=true
            shift
            ;;
        --overwrite)
            OVERWRITE=true
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

# Import specific file
if [[ -n "$IMPORT_FILE" ]]; then
    if [[ "$IMPORT_CONFIG" == true ]]; then
        import_config "$IMPORT_FILE" "$OVERWRITE"
    else
        import_image "$IMPORT_FILE" "$TARGET_TAG" "$OVERWRITE"
    fi
    exit 0
fi

# Import from directory
if [[ ! -d "$IMPORT_DIR" ]]; then
    print_error "Import directory not found: $IMPORT_DIR"
    exit 1
fi

print_status "Importing from directory: $IMPORT_DIR"

# Import all files
if [[ "$IMPORT_ALL" == true ]]; then
    print_status "Importing all files from directory..."
    
    # Find all image files
    mapfile -t image_files < <(find "$IMPORT_DIR" -name "*.tar" -o -name "*.tar.gz" 2>/dev/null | grep -v config)
    
    if [[ ${#image_files[@]} -eq 0 ]]; then
        print_warning "No image files found in directory"
    else
        for file in "${image_files[@]}"; do
            if [[ -f "$file" ]]; then
                import_image "$file" "$TARGET_TAG" "$OVERWRITE"
            fi
        done
    fi
    
    # Find configuration files
    if [[ "$IMPORT_CONFIG" == true ]]; then
        mapfile -t config_files < <(find "$IMPORT_DIR" -name "*config*" \( -name "*.tar" -o -name "*.tar.gz" \) 2>/dev/null)
        
        if [[ ${#config_files[@]} -eq 0 ]]; then
            print_warning "No configuration files found in directory"
        else
            for file in "${config_files[@]}"; do
                if [[ -f "$file" ]]; then
                    import_config "$file" "$OVERWRITE"
                fi
            done
        fi
    fi
else
    # Import specific version
    if [[ "$USE_GPU" == true ]]; then
        print_status "Looking for GPU version files..."
        mapfile -t files < <(find_import_files "$IMPORT_DIR" true)
    else
        print_status "Looking for CPU version files..."
        mapfile -t files < <(find_import_files "$IMPORT_DIR" false)
    fi
    
    if [[ ${#files[@]} -eq 0 ]]; then
        print_error "No suitable files found in directory"
        exit 1
    fi
    
    # Import first found file
    import_image "${files[0]}" "$TARGET_TAG" "$OVERWRITE"
fi

print_success "Import completed!"
print_status "You can now run the container using: ./run.sh"
if [[ "$USE_GPU" == true ]]; then
    print_status "For GPU version: ./run.sh --gpu"
fi 