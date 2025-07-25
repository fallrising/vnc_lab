#!/bin/bash

# VNC Lab - novnc_base Test Script
# Test basic VNC functionality and container health

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONTAINER_NAME="vnc-base-container"
IMAGE_NAME="vnc-base"
DEFAULT_VNC_PORT="6080"
DEFAULT_VNC_DIRECT_PORT="5900"

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
    echo "  --container             Test running container"
    echo "  --host                  Test host system"
    echo "  --all                   Test everything (default)"
    echo "  -p, --port PORT         VNC port to test (default: $DEFAULT_VNC_PORT)"
    echo "  -P, --direct-port PORT  Direct VNC port to test (default: $DEFAULT_VNC_DIRECT_PORT)"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                      # Test everything"
    echo "  $0 --container          # Test running container only"
    echo "  $0 --host               # Test host system only"
    echo "  $0 -p 9000 -P 5901     # Test with custom ports"
}

# Parse command line arguments
TEST_CONTAINER=false
TEST_HOST=false
VNC_PORT=$DEFAULT_VNC_PORT
VNC_DIRECT_PORT=$DEFAULT_VNC_DIRECT_PORT

while [[ $# -gt 0 ]]; do
    case $1 in
        --container)
            TEST_CONTAINER=true
            shift
            ;;
        --host)
            TEST_HOST=true
            shift
            ;;
        --all)
            TEST_CONTAINER=true
            TEST_HOST=true
            shift
            ;;
        -p|--port)
            VNC_PORT="$2"
            shift 2
            ;;
        -P|--direct-port)
            VNC_DIRECT_PORT="$2"
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

# If no specific test is specified, test everything
if [[ "$TEST_CONTAINER" == false ]] && [[ "$TEST_HOST" == false ]]; then
    TEST_CONTAINER=true
    TEST_HOST=true
fi

# Function to test Docker
test_docker() {
    print_status "Testing Docker installation..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed!"
        return 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running or not accessible!"
        return 1
    fi
    
    print_success "Docker is working properly"
    docker --version
}

# Function to test image
test_image() {
    print_status "Testing base image..."
    
    if ! docker images "$IMAGE_NAME:latest" | grep -q "$IMAGE_NAME"; then
        print_warning "Base image '$IMAGE_NAME:latest' not found!"
        print_status "You can build it using: ./build.sh"
        return 1
    fi
    
    print_success "Base image exists"
    docker images "$IMAGE_NAME:latest" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
}

# Function to test container
test_container() {
    print_status "Testing container functionality..."
    
    # Check if container is running
    if ! docker ps --filter "name=$CONTAINER_NAME" --format "{{.Names}}" | grep -q "$CONTAINER_NAME"; then
        print_warning "Container '$CONTAINER_NAME' is not running!"
        print_status "You can start it using: ./run.sh"
        return 1
    fi
    
    print_success "Container is running"
    
    # Check container health
    print_status "Checking container health..."
    
    # Test VNC web port
    if curl -s "http://localhost:$VNC_PORT" >/dev/null 2>&1; then
        print_success "VNC web interface is accessible at http://localhost:$VNC_PORT"
    else
        print_error "VNC web interface is not accessible at http://localhost:$VNC_PORT"
    fi
    
    # Test direct VNC port
    if nc -z localhost "$VNC_DIRECT_PORT" 2>/dev/null; then
        print_success "Direct VNC port $VNC_DIRECT_PORT is listening"
    else
        print_warning "Direct VNC port $VNC_DIRECT_PORT is not accessible"
    fi
    
    # Check container logs
    print_status "Checking container logs..."
    if docker logs "$CONTAINER_NAME" 2>&1 | grep -q "error\|Error\|ERROR"; then
        print_warning "Container logs contain errors:"
        docker logs "$CONTAINER_NAME" 2>&1 | grep -i "error" | tail -5
    else
        print_success "No errors found in container logs"
    fi
    
    # Check container resources
    print_status "Checking container resources..."
    docker stats "$CONTAINER_NAME" --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
}

# Function to test host system
test_host() {
    print_status "Testing host system..."
    
    # Check system resources
    print_status "Checking system resources..."
    
    # Memory
    MEMORY_AVAILABLE=$(free -h | grep Mem | awk '{print $7}')
    print_status "Available memory: $MEMORY_AVAILABLE"
    
    # Disk space
    DISK_AVAILABLE=$(df -h . | tail -1 | awk '{print $4}')
    print_status "Available disk space: $DISK_AVAILABLE"
    
    # Check if ports are available
    print_status "Checking port availability..."
    
    if lsof -i ":$VNC_PORT" >/dev/null 2>&1; then
        print_success "Port $VNC_PORT is available"
    else
        print_warning "Port $VNC_PORT might be in use"
    fi
    
    if lsof -i ":$VNC_DIRECT_PORT" >/dev/null 2>&1; then
        print_success "Port $VNC_DIRECT_PORT is available"
    else
        print_warning "Port $VNC_DIRECT_PORT might be in use"
    fi
    
    # Check network connectivity
    print_status "Testing network connectivity..."
    
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        print_success "Internet connectivity is working"
    else
        print_warning "Internet connectivity might be limited"
    fi
}

# Function to test VNC functionality
test_vnc_functionality() {
    print_status "Testing VNC functionality..."
    
    # Test noVNC web interface
    print_status "Testing noVNC web interface..."
    
    if curl -s "http://localhost:$VNC_PORT" | grep -q "noVNC\|VNC"; then
        print_success "noVNC web interface is working"
    else
        print_error "noVNC web interface is not working properly"
    fi
    
    # Test if we can connect to the VNC server
    print_status "Testing VNC server connection..."
    
    if timeout 5 bash -c "</dev/tcp/localhost/$VNC_DIRECT_PORT" 2>/dev/null; then
        print_success "VNC server is accepting connections"
    else
        print_warning "VNC server connection test failed"
    fi
}

# Main test execution
print_status "Starting VNC Base tests..."

# Test Docker
test_docker

# Test image
test_image

# Test host system if requested
if [[ "$TEST_HOST" == true ]]; then
    test_host
fi

# Test container if requested
if [[ "$TEST_CONTAINER" == true ]]; then
    test_container
    test_vnc_functionality
fi

print_success "VNC Base tests completed!"

# Summary
echo
print_status "Test Summary:"
print_status "  - Docker: $(test_docker >/dev/null 2>&1 && echo 'OK' || echo 'FAILED')"
print_status "  - Image: $(test_image >/dev/null 2>&1 && echo 'OK' || echo 'FAILED')"
if [[ "$TEST_HOST" == true ]]; then
    print_status "  - Host System: OK"
fi
if [[ "$TEST_CONTAINER" == true ]]; then
    print_status "  - Container: $(test_container >/dev/null 2>&1 && echo 'OK' || echo 'FAILED')"
    print_status "  - VNC Functionality: $(test_vnc_functionality >/dev/null 2>&1 && echo 'OK' || echo 'FAILED')"
fi 