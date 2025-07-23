#!/bin/bash

# VNC Lab - novnc_warp Test Script
# Test Warp terminal functionality and AMD GPU support

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONTAINER_NAME="vnc-warp-test"
TEST_TIMEOUT=30

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
    echo "  --gpu                   Test GPU version"
    echo "  --container             Test inside running container"
    echo "  --host                  Test host system"
    echo "  --all                   Run all tests"
    echo "  --timeout SECONDS       Test timeout (default: $TEST_TIMEOUT)"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                      # Basic functionality test"
    echo "  $0 --gpu               # Test GPU version"
    echo "  $0 --container         # Test inside container"
    echo "  $0 --host              # Test host system"
    echo "  $0 --all               # Run comprehensive tests"
}

# Function to test host system
test_host_system() {
    print_status "Testing host system..."
    
    # Check Docker
    if command -v docker &> /dev/null; then
        print_success "Docker is available"
        docker --version
    else
        print_error "Docker is not available"
        return 1
    fi
    
    # Check AMD GPU
    print_status "Checking AMD GPU support..."
    if lspci | grep -i amd | grep -i vga &> /dev/null; then
        print_success "AMD GPU detected:"
        lspci | grep -i amd | grep -i vga
    else
        print_warning "AMD GPU not detected on host"
    fi
    
    # Check OpenGL
    if command -v glxinfo &> /dev/null; then
        print_status "OpenGL information:"
        glxinfo | grep -i "OpenGL vendor\|OpenGL renderer" | head -2
    else
        print_warning "glxinfo not available"
    fi
    
    # Check Vulkan
    if command -v vulkaninfo &> /dev/null; then
        print_status "Vulkan information:"
        vulkaninfo --summary 2>/dev/null | head -5 || print_warning "Vulkan not available"
    else
        print_warning "vulkaninfo not available"
    fi
}

# Function to test container
test_container() {
    local gpu=$1
    
    print_status "Testing container..."
    
    # Check if container is running
    if ! docker ps --format "{{.Names}}" | grep -q "$CONTAINER_NAME"; then
        print_error "Container $CONTAINER_NAME is not running!"
        print_status "Start container first: ./run.sh"
        if [[ "$gpu" == true ]]; then
            print_status "For GPU version: ./run.sh --gpu"
        fi
        return 1
    fi
    
    print_success "Container $CONTAINER_NAME is running"
    
    # Test basic container functionality
    print_status "Testing container basic functionality..."
    
    # Check if Warp is installed
    if docker exec "$CONTAINER_NAME" which warp &> /dev/null; then
        print_success "Warp is installed"
        docker exec "$CONTAINER_NAME" warp --version
    else
        print_error "Warp is not installed in container"
        return 1
    fi
    
    # Check Rust
    if docker exec "$CONTAINER_NAME" which rustc &> /dev/null; then
        print_success "Rust is installed"
        docker exec "$CONTAINER_NAME" rustc --version
    else
        print_error "Rust is not installed in container"
        return 1
    fi
    
    # Test GPU support inside container
    if [[ "$gpu" == true ]]; then
        print_status "Testing GPU support inside container..."
        
        # Check AMD GPU device
        if docker exec "$CONTAINER_NAME" ls /dev/dri &> /dev/null; then
            print_success "AMD GPU device available in container"
            docker exec "$CONTAINER_NAME" ls -la /dev/dri
        else
            print_warning "AMD GPU device not available in container"
        fi
        
        # Check OpenGL inside container
        if docker exec "$CONTAINER_NAME" which glxinfo &> /dev/null; then
            print_status "OpenGL information inside container:"
            docker exec "$CONTAINER_NAME" glxinfo | grep -i "OpenGL vendor\|OpenGL renderer" | head -2
        else
            print_warning "glxinfo not available in container"
        fi
        
        # Check Vulkan inside container
        if docker exec "$CONTAINER_NAME" which vulkaninfo &> /dev/null; then
            print_status "Vulkan information inside container:"
            docker exec "$CONTAINER_NAME" vulkaninfo --summary 2>/dev/null | head -5 || print_warning "Vulkan not available in container"
        else
            print_warning "vulkaninfo not available in container"
        fi
    fi
    
    # Test network connectivity (for AI features)
    print_status "Testing network connectivity for AI features..."
    if docker exec "$CONTAINER_NAME" ping -c 1 8.8.8.8 &> /dev/null; then
        print_success "Network connectivity is working"
    else
        print_warning "Network connectivity issues detected"
    fi
    
    # Test curl for API access
    if docker exec "$CONTAINER_NAME" curl -s --connect-timeout 5 https://api.openai.com &> /dev/null; then
        print_success "External API access is working"
    else
        print_warning "External API access may be limited"
    fi
}

# Function to test Warp functionality
test_warp_functionality() {
    local gpu=$1
    
    print_status "Testing Warp functionality..."
    
    # Start container if not running
    if ! docker ps --format "{{.Names}}" | grep -q "$CONTAINER_NAME"; then
        print_status "Starting test container..."
        if [[ "$gpu" == true ]]; then
            ./run.sh --gpu -n "$CONTAINER_NAME" -d
        else
            ./run.sh -n "$CONTAINER_NAME" -d
        fi
        
        # Wait for container to start
        sleep 5
    fi
    
    # Test Warp startup
    print_status "Testing Warp startup..."
    if docker exec "$CONTAINER_NAME" timeout 10 warp --help &> /dev/null; then
        print_success "Warp starts successfully"
    else
        print_error "Warp failed to start"
        return 1
    fi
    
    # Test Warp configuration
    print_status "Testing Warp configuration..."
    if docker exec "$CONTAINER_NAME" test -d /home/warp/.config/warp; then
        print_success "Warp configuration directory exists"
    else
        print_warning "Warp configuration directory not found"
    fi
    
    # Test workspace directory
    print_status "Testing workspace directory..."
    if docker exec "$CONTAINER_NAME" test -d /home/warp/workspace; then
        print_success "Workspace directory exists"
    else
        print_warning "Workspace directory not found"
    fi
    
    # Test user permissions
    print_status "Testing user permissions..."
    if docker exec "$CONTAINER_NAME" test -w /home/warp/workspace; then
        print_success "User has write permissions to workspace"
    else
        print_error "User lacks write permissions to workspace"
        return 1
    fi
}

# Function to run comprehensive tests
run_comprehensive_tests() {
    print_status "Running comprehensive tests..."
    
    # Test host system
    test_host_system
    
    echo ""
    
    # Test CPU version
    print_status "Testing CPU version..."
    test_warp_functionality false
    
    echo ""
    
    # Test GPU version
    print_status "Testing GPU version..."
    test_warp_functionality true
    
    echo ""
    
    # Clean up test container
    print_status "Cleaning up test container..."
    docker stop "$CONTAINER_NAME" &> /dev/null || true
    docker rm "$CONTAINER_NAME" &> /dev/null || true
    
    print_success "Comprehensive tests completed!"
}

# Parse command line arguments
USE_GPU=false
TEST_CONTAINER=false
TEST_HOST=false
TEST_ALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --gpu)
            USE_GPU=true
            shift
            ;;
        --container)
            TEST_CONTAINER=true
            shift
            ;;
        --host)
            TEST_HOST=true
            shift
            ;;
        --all)
            TEST_ALL=true
            shift
            ;;
        --timeout)
            TEST_TIMEOUT="$2"
            shift 2
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

# Run tests based on options
if [[ "$TEST_ALL" == true ]]; then
    run_comprehensive_tests
elif [[ "$TEST_HOST" == true ]]; then
    test_host_system
elif [[ "$TEST_CONTAINER" == true ]]; then
    test_container "$USE_GPU"
else
    # Default: test Warp functionality
    test_warp_functionality "$USE_GPU"
fi

print_success "Tests completed!" 