#!/bin/bash

# VNC Lab - novnc_base Import Script
# Import Docker image from tar file

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="vnc-base"
DEFAULT_INPUT_DIR="./exports"

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
    echo "  -f, --file FILE         Specific tar file to import"
    echo "  -d, --directory DIR     Directory to search for tar files (default: $DEFAULT_INPUT_DIR)"
    echo "  --all                   Import all tar files in directory"
    echo "  --overwrite             Overwrite existing images"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -f image.tar         # Import specific file"
    echo "  $0 -f image.tar.gz      # Import compressed file"
    echo "  $0 -d /path/to/exports  # Import from specific directory"
    echo "  $0 --all                # Import all tar files in default directory"
    echo "  $0 --all --overwrite    # Import all and overwrite existing"
}

# Parse command line arguments
INPUT_FILE=""
INPUT_DIR=$DEFAULT_INPUT_DIR
IMPORT_ALL=false
OVERWRITE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            INPUT_FILE="$2"
            shift 2
            ;;
        -d|--directory)
            INPUT_DIR="$2"
            shift 2
            ;;
        --all)
            IMPORT_ALL=true
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

# Function to import single file
import_file() {
    local file_path=$1
    
    # Check if file exists
    if [[ ! -f "$file_path" ]]; then
        print_warning "File not found: $file_path"
        return 1
    fi
    
    # Check file type
    if [[ "$file_path" == *.tar.gz ]] || [[ "$file_path" == *.tgz ]]; then
        print_status "Importing compressed file: $file_path"
        if gunzip -c "$file_path" | docker load; then
            print_success "Successfully imported $file_path"
            return 0
        else
            print_error "Failed to import $file_path"
            return 1
        fi
    elif [[ "$file_path" == *.tar ]]; then
        print_status "Importing tar file: $file_path"
        if docker load -i "$file_path"; then
            print_success "Successfully imported $file_path"
            return 0
        else
            print_error "Failed to import $file_path"
            return 1
        fi
    else
        print_warning "Unsupported file type: $file_path"
        return 1
    fi
}

# Function to check for existing images
check_existing_images() {
    local file_path=$1
    local filename=$(basename "$file_path")
    
    # Try to extract image name from filename
    local extracted_name=""
    if [[ "$filename" =~ ^([^_]+)_([^_]+)_ ]]; then
        extracted_name="${BASH_REMATCH[1]}"
        local extracted_tag="${BASH_REMATCH[2]}"
        
        if docker images "$extracted_name:$extracted_tag" | grep -q "$extracted_name"; then
            if [[ "$OVERWRITE" == false ]]; then
                print_warning "Image $extracted_name:$extracted_tag already exists!"
                read -p "Do you want to overwrite it? (y/N): " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    return 1
                fi
            fi
            
            print_status "Removing existing image $extracted_name:$extracted_tag..."
            docker rmi "$extracted_name:$extracted_tag" >/dev/null 2>&1 || true
        fi
    fi
}

# Import images
if [[ -n "$INPUT_FILE" ]]; then
    # Import specific file
    if [[ "$INPUT_FILE" == /* ]]; then
        # Absolute path
        file_path="$INPUT_FILE"
    else
        # Relative path
        file_path="$INPUT_DIR/$INPUT_FILE"
    fi
    
    check_existing_images "$file_path"
    if import_file "$file_path"; then
        print_success "Import completed successfully!"
    else
        print_error "Import failed!"
        exit 1
    fi
elif [[ "$IMPORT_ALL" == true ]]; then
    # Import all tar files in directory
    if [[ ! -d "$INPUT_DIR" ]]; then
        print_error "Directory not found: $INPUT_DIR"
        exit 1
    fi
    
    print_status "Searching for tar files in $INPUT_DIR..."
    
    # Find all tar files
    TAR_FILES=$(find "$INPUT_DIR" -maxdepth 1 -type f \( -name "*.tar" -o -name "*.tar.gz" -o -name "*.tgz" \) | sort)
    
    if [[ -z "$TAR_FILES" ]]; then
        print_warning "No tar files found in $INPUT_DIR"
        exit 1
    fi
    
    print_status "Found $(echo "$TAR_FILES" | wc -l) tar file(s)"
    
    SUCCESS_COUNT=0
    TOTAL_COUNT=0
    
    for file in $TAR_FILES; do
        TOTAL_COUNT=$((TOTAL_COUNT + 1))
        print_status "Processing $TOTAL_COUNT/$(echo "$TAR_FILES" | wc -l): $(basename "$file")"
        
        check_existing_images "$file"
        if import_file "$file"; then
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        fi
    done
    
    print_status "Import completed: $SUCCESS_COUNT/$TOTAL_COUNT files imported successfully"
    
    if [[ $SUCCESS_COUNT -eq $TOTAL_COUNT ]]; then
        print_success "All files imported successfully!"
    else
        print_warning "Some files failed to import"
        exit 1
    fi
else
    print_error "Please specify either -f/--file or --all option"
    show_usage
    exit 1
fi

# Show imported images
print_status "Imported images:"
docker images "$IMAGE_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" 2>/dev/null || print_warning "No $IMAGE_NAME images found" 