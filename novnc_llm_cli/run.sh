#!/bin/bash

# VNC Lab - novnc_llm_cli Run Script
# Run Docker container for AI tools integrated VNC environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="vnc-llm-cli"
DEFAULT_TAG="latest"
CONTAINER_NAME="vnc-llm-cli-container"
DEFAULT_VNC_PORT="6080"
DEFAULT_VNC_CLIENT_PORT="5900"
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
    echo "  -t, --tag TAG           Image tag (default: $DEFAULT_TAG)"
    echo "  -n, --name NAME         Container name (default: $CONTAINER_NAME)"
    echo "  -p, --vnc-port PORT     VNC web port (default: $DEFAULT_VNC_PORT)"
    echo "  -c, --client-port PORT  VNC client port (default: $DEFAULT_VNC_CLIENT_PORT)"
    echo "  -T, --terminal-port PORT Web terminal port (default: $DEFAULT_TERMINAL_PORT)"
    echo "  -d, --detach            Run in background"
    echo "  --rm                    Remove container when stopped"
    echo "  -v, --volume PATH       Mount volume (format: host:container)"
    echo "  -m, --memory SIZE       Memory limit (e.g., 1g, 2g)"
    echo "  --cpus NUM              CPU limit (e.g., 1.0, 2.0)"
    echo "  --vnc-password PASS     Set VNC password"
    echo "  --terminal-password PASS Set terminal password"
    echo "  --tunnel-token TOKEN    Cloudflare tunnel token"
    echo "  --env-file FILE         Load environment variables from file"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                      # Run with default settings"
    echo "  $0 -d                   # Run in background"
    echo "  $0 -p 8080 -T 9000      # Use custom ports"
    echo "  $0 -v /path:/workspace  # Mount volume"
    echo "  $0 --vnc-password mypass --terminal-password termpass"
    echo "  $0 --env-file .env      # Load from environment file"
}

# Parse command line arguments
TAG=$DEFAULT_TAG
CONTAINER_NAME_ARG=""
VNC_PORT=$DEFAULT_VNC_PORT
VNC_CLIENT_PORT=$DEFAULT_VNC_CLIENT_PORT
TERMINAL_PORT=$DEFAULT_TERMINAL_PORT
DETACH=""
RM=""
VOLUMES=""
MEMORY=""
CPUS=""
VNC_PASSWORD=""
TERMINAL_PASSWORD=""
TUNNEL_TOKEN=""
ENV_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--tag)
            TAG="$2"
            shift 2
            ;;
        -n|--name)
            CONTAINER_NAME_ARG="$2"
            shift 2
            ;;
        -p|--vnc-port)
            VNC_PORT="$2"
            shift 2
            ;;
        -c|--client-port)
            VNC_CLIENT_PORT="$2"
            shift 2
            ;;
        -T|--terminal-port)
            TERMINAL_PORT="$2"
            shift 2
            ;;
        -d|--detach)
            DETACH="-d"
            shift
            ;;
        --rm)
            RM="--rm"
            shift
            ;;
        -v|--volume)
            VOLUMES="$VOLUMES -v $2"
            shift 2
            ;;
        -m|--memory)
            MEMORY="--memory=$2"
            shift 2
            ;;
        --cpus)
            CPUS="--cpus=$2"
            shift 2
            ;;
        --vnc-password)
            VNC_PASSWORD="$2"
            shift 2
            ;;
        --terminal-password)
            TERMINAL_PASSWORD="$2"
            shift 2
            ;;
        --tunnel-token)
            TUNNEL_TOKEN="$2"
            shift 2
            ;;
        --env-file)
            ENV_FILE="$2"
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

# Set container name
if [[ -n "$CONTAINER_NAME_ARG" ]]; then
    CONTAINER_NAME="$CONTAINER_NAME_ARG"
fi

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running or not accessible!"
    exit 1
fi

# Check if image exists
FULL_IMAGE_NAME="$IMAGE_NAME:$TAG"
if ! docker images "$FULL_IMAGE_NAME" | grep -q "$IMAGE_NAME"; then
    print_warning "Image $FULL_IMAGE_NAME not found!"
    print_status "You can build it using: ./build.sh -t $TAG"
    exit 1
fi

# Check if container name is already in use
if docker ps -a --format "table {{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
    print_warning "Container '$CONTAINER_NAME' already exists!"
    read -p "Do you want to remove it and create a new one? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Removing existing container..."
        docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
    else
        print_error "Container name conflict. Please use a different name with -n option."
        exit 1
    fi
fi

# Build docker run command
DOCKER_RUN_CMD="docker run $DETACH $RM"
DOCKER_RUN_CMD="$DOCKER_RUN_CMD --name $CONTAINER_NAME"
DOCKER_RUN_CMD="$DOCKER_RUN_CMD -p 127.0.0.1:$VNC_PORT:6080"
DOCKER_RUN_CMD="$DOCKER_RUN_CMD -p 127.0.0.1:$VNC_CLIENT_PORT:5900"
DOCKER_RUN_CMD="$DOCKER_RUN_CMD -p 127.0.0.1:$TERMINAL_PORT:7681"
DOCKER_RUN_CMD="$DOCKER_RUN_CMD $VOLUMES"
DOCKER_RUN_CMD="$DOCKER_RUN_CMD $MEMORY"
DOCKER_RUN_CMD="$DOCKER_RUN_CMD $CPUS"

# Add environment variables
if [[ -n "$VNC_PASSWORD" ]]; then
    DOCKER_RUN_CMD="$DOCKER_RUN_CMD -e VNC_PASSWORD=$VNC_PASSWORD"
fi

if [[ -n "$TERMINAL_PASSWORD" ]]; then
    DOCKER_RUN_CMD="$DOCKER_RUN_CMD -e TTYD_PASSWORD=$TERMINAL_PASSWORD"
fi

if [[ -n "$TUNNEL_TOKEN" ]]; then
    DOCKER_RUN_CMD="$DOCKER_RUN_CMD -e TUNNEL_TOKEN=$TUNNEL_TOKEN"
fi

if [[ -n "$ENV_FILE" ]]; then
    DOCKER_RUN_CMD="$DOCKER_RUN_CMD --env-file $ENV_FILE"
fi

DOCKER_RUN_CMD="$DOCKER_RUN_CMD $FULL_IMAGE_NAME"

# Run the container
print_status "Starting container '$CONTAINER_NAME'..."
print_status "Image: $FULL_IMAGE_NAME"
print_status "VNC Web: http://localhost:$VNC_PORT"
print_status "VNC Client: localhost:$VNC_CLIENT_PORT"
print_status "Web Terminal: http://localhost:$TERMINAL_PORT"

if eval $DOCKER_RUN_CMD; then
    print_success "Container started successfully!"
    
    if [[ -n "$DETACH" ]]; then
        print_status "Container is running in background."
        print_status "To view logs: docker logs $CONTAINER_NAME"
        print_status "To stop: docker stop $CONTAINER_NAME"
        print_status "To access shell: docker exec -it $CONTAINER_NAME bash"
        print_status "To debug: docker exec $CONTAINER_NAME /opt/scripts/debug.sh"
    fi
    
    print_status "Access your services:"
    print_status "  - Desktop: http://localhost:$VNC_PORT"
    print_status "  - Terminal: http://localhost:$TERMINAL_PORT"
    
    if [[ -n "$VNC_PASSWORD" ]]; then
        print_status "  - VNC Password: $VNC_PASSWORD"
    fi
    
    if [[ -n "$TERMINAL_PASSWORD" ]]; then
        print_status "  - Terminal Password: $TERMINAL_PASSWORD"
    fi
else
    print_error "Failed to start container!"
    exit 1
fi 