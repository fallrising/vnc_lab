#!/bin/bash

# VNC Lab - novnc_llm_cli Test Script
# Test AI tools functionality and container health

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONTAINER_NAME="vnc-llm-cli-container"
IMAGE_NAME="vnc-llm-cli"
DEFAULT_VNC_PORT="6080"
DEFAULT_TERMINAL_PORT="7681"

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
    echo "  --ai-tools              Test AI tools functionality"
    echo "  -p, --port PORT         VNC port to test (default: $DEFAULT_VNC_PORT)"
    echo "  -T, --terminal-port PORT Terminal port to test (default: $DEFAULT_TERMINAL_PORT)"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                      # Test everything"
    echo "  $0 --container          # Test running container only"
    echo "  $0 --ai-tools           # Test AI tools functionality"
    echo "  $0 -p 9000 -T 9001     # Test with custom ports"
}

# Parse command line arguments
TEST_CONTAINER=false
TEST_HOST=false
TEST_AI_TOOLS=false
VNC_PORT=$DEFAULT_VNC_PORT
TERMINAL_PORT=$DEFAULT_TERMINAL_PORT

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
            TEST_AI_TOOLS=true
            shift
            ;;
        --ai-tools)
            TEST_AI_TOOLS=true
            shift
            ;;
        -p|--port)
            VNC_PORT="$2"
            shift 2
            ;;
        -T|--terminal-port)
            TERMINAL_PORT="$2"
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
if [[ "$TEST_CONTAINER" == false ]] && [[ "$TEST_HOST" == false ]] && [[ "$TEST_AI_TOOLS" == false ]]; then
    TEST_CONTAINER=true
    TEST_HOST=true
    TEST_AI_TOOLS=true
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
    print_status "Testing LLM CLI image..."
    
    if ! docker images "$IMAGE_NAME:latest" | grep -q "$IMAGE_NAME"; then
        print_warning "LLM CLI image '$IMAGE_NAME:latest' not found!"
        print_status "You can build it using: ./build.sh"
        return 1
    fi
    
    print_success "LLM CLI image exists"
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
    
    # Test web terminal port
    if curl -s "http://localhost:$TERMINAL_PORT" >/dev/null 2>&1; then
        print_success "Web terminal is accessible at http://localhost:$TERMINAL_PORT"
    else
        print_error "Web terminal is not accessible at http://localhost:$TERMINAL_PORT"
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

# Function to test AI tools
test_ai_tools() {
    print_status "Testing AI tools functionality..."
    
    # Check Node.js
    if docker exec "$CONTAINER_NAME" which node &> /dev/null; then
        NODE_VERSION=$(docker exec "$CONTAINER_NAME" node --version)
        print_success "Node.js is installed: $NODE_VERSION"
    else
        print_error "Node.js is not installed"
        return 1
    fi
    
    # Check npm
    if docker exec "$CONTAINER_NAME" which npm &> /dev/null; then
        NPM_VERSION=$(docker exec "$CONTAINER_NAME" npm --version)
        print_success "npm is installed: $NPM_VERSION"
    else
        print_error "npm is not installed"
        return 1
    fi
    
    # Check Google Gemini CLI
    if docker exec "$CONTAINER_NAME" which gemini &> /dev/null; then
        print_success "Google Gemini CLI is installed"
        GEMINI_VERSION=$(docker exec "$CONTAINER_NAME" gemini --version 2>/dev/null || echo "Version not available")
        print_status "Gemini version: $GEMINI_VERSION"
    else
        print_warning "Google Gemini CLI is not installed"
    fi
    
    # Check Anthropic Claude Code
    if docker exec "$CONTAINER_NAME" which claude-code &> /dev/null; then
        print_success "Anthropic Claude Code is installed"
        CLAUDE_VERSION=$(docker exec "$CONTAINER_NAME" claude-code --version 2>/dev/null || echo "Version not available")
        print_status "Claude Code version: $CLAUDE_VERSION"
    else
        print_warning "Anthropic Claude Code is not installed"
    fi
    
    # Check Atlassian CLI
    if docker exec "$CONTAINER_NAME" which acli &> /dev/null; then
        print_success "Atlassian CLI is installed"
        ACLI_VERSION=$(docker exec "$CONTAINER_NAME" acli --version 2>/dev/null || echo "Version not available")
        print_status "Atlassian CLI version: $ACLI_VERSION"
    else
        print_warning "Atlassian CLI is not installed"
    fi
    
    # Check ttyd
    if docker exec "$CONTAINER_NAME" which ttyd &> /dev/null; then
        print_success "ttyd is installed"
        TTYD_VERSION=$(docker exec "$CONTAINER_NAME" ttyd --version 2>/dev/null || echo "Version not available")
        print_status "ttyd version: $TTYD_VERSION"
    else
        print_warning "ttyd is not installed"
    fi
    
    # Check cloudflared
    if docker exec "$CONTAINER_NAME" which cloudflared &> /dev/null; then
        print_success "cloudflared is installed"
        CLOUDFLARED_VERSION=$(docker exec "$CONTAINER_NAME" cloudflared --version 2>/dev/null || echo "Version not available")
        print_status "cloudflared version: $CLOUDFLARED_VERSION"
    else
        print_warning "cloudflared is not installed"
    fi
    
    # Check if AI tools processes are running
    print_status "Checking AI tools processes..."
    
    if docker exec "$CONTAINER_NAME" ps aux | grep -v grep | grep -q ttyd; then
        print_success "ttyd process is running"
    else
        print_warning "ttyd process is not running"
    fi
    
    if docker exec "$CONTAINER_NAME" ps aux | grep -v grep | grep -q cloudflared; then
        print_success "cloudflared process is running"
    else
        print_warning "cloudflared process is not running"
    fi
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
    
    if lsof -i ":$TERMINAL_PORT" >/dev/null 2>&1; then
        print_success "Port $TERMINAL_PORT is available"
    else
        print_warning "Port $TERMINAL_PORT might be in use"
    fi
    
    # Check network connectivity
    print_status "Testing network connectivity..."
    
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        print_success "Internet connectivity is working"
    else
        print_warning "Internet connectivity might be limited"
    fi
}

# Main test execution
print_status "Starting LLM CLI tests..."

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
fi

# Test AI tools if requested
if [[ "$TEST_AI_TOOLS" == true ]]; then
    test_ai_tools
fi

print_success "LLM CLI tests completed!"

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
fi
if [[ "$TEST_AI_TOOLS" == true ]]; then
    print_status "  - AI Tools: $(test_ai_tools >/dev/null 2>&1 && echo 'OK' || echo 'FAILED')"
fi 