#!/bin/bash

# AMD GPU Test Script for novnc_cursor
# Test AMD GPU support and OpenGL capabilities

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

print_status "Testing AMD GPU support..."

# Check if we're in a container
if [[ -f /.dockerenv ]]; then
    print_status "Running inside container"
    
    # Check for AMD GPU devices
    if [[ -d "/dev/dri" ]]; then
        print_success "DRI devices found:"
        ls -la /dev/dri/
    else
        print_warning "No DRI devices found"
    fi
    
    # Check for video group
    if groups | grep -q video; then
        print_success "User is in video group"
    else
        print_warning "User is not in video group"
    fi
    
    # Check OpenGL support
    if command -v glxinfo &> /dev/null; then
        print_status "OpenGL Information:"
        glxinfo | grep -i "OpenGL vendor\|OpenGL renderer\|OpenGL version" | head -3
    else
        print_warning "glxinfo not available"
    fi
    
    # Check Mesa version
    if command -v glxinfo &> /dev/null; then
        print_status "Mesa Information:"
        glxinfo | grep -i "Mesa" | head -2
    fi
    
    # Check Vulkan support
    if command -v vulkaninfo &> /dev/null; then
        print_status "Vulkan Information:"
        vulkaninfo --summary 2>/dev/null | head -5 || print_warning "Vulkan not available"
    else
        print_warning "vulkaninfo not available"
    fi
    
else
    print_status "Running on host system"
    
    # Check for AMD GPU
    if lspci | grep -i amd | grep -i vga; then
        print_success "AMD GPU detected on host"
    else
        print_warning "No AMD GPU detected on host"
    fi
    
    # Check OpenGL support
    if command -v glxinfo &> /dev/null; then
        print_status "Host OpenGL Information:"
        glxinfo | grep -i "OpenGL vendor\|OpenGL renderer" | head -2
    fi
    
    # Check if Docker is available
    if command -v docker &> /dev/null; then
        print_status "Docker is available"
        
        # Test running the container
        print_status "Testing container GPU support..."
        if docker run --rm --device=/dev/dri:/dev/dri --group-add video vnc-cursor-gpu:latest bash -c "
            echo 'Testing GPU support in container...'
            if [[ -d '/dev/dri' ]]; then
                echo 'DRI devices found:'
                ls -la /dev/dri/
            fi
            if groups | grep -q video; then
                echo 'User in video group'
            fi
            if command -v glxinfo &> /dev/null; then
                echo 'OpenGL vendor:'
                glxinfo | grep -i 'OpenGL vendor' | head -1
            fi
        "; then
            print_success "Container GPU test completed"
        else
            print_error "Container GPU test failed"
        fi
    else
        print_warning "Docker not available"
    fi
fi

print_status "AMD GPU test completed" 