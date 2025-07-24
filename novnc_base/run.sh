#!/bin/bash

# VNC Base Container Management Script
# Supports both localhost and subdomain access via environment variables

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default configuration
IMAGE_NAME="vnc-base"
CONTAINER_NAME="vnc-base"
VNC_PORT="6080"
VNC_CLIENT_PORT="5900"
VNC_HOST="0.0.0.0"
VNC_BACKEND_HOST="localhost"
VNC_BACKEND_PORT="5900"
DETACH=""
RM="--rm"
VOLUMES=""
MEMORY=""
CPUS=""
ENV_FILE=""

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

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -d, --detach            Run container in background"
    echo "  -n, --name NAME         Container name (default: vnc-base)"
    echo "  -p, --port PORT         VNC web port (default: 6080)"
    echo "  -P, --client-port PORT  Direct VNC port (default: 5900)"
    echo "  -H, --host HOST         VNC host binding (default: 0.0.0.0)"
    echo "  -b, --backend-host HOST VNC backend host (default: localhost)"
    echo "  -B, --backend-port PORT VNC backend port (default: 5900)"
    echo "  -v, --volume PATH       Mount volume (can be used multiple times)"
    echo "  -m, --memory SIZE       Memory limit (e.g., 1g, 2g)"
    echo "  -c, --cpus NUM          CPU limit (e.g., 1.0, 2.0)"
    echo "  -e, --env-file FILE     Environment file"
    echo "  -t, --tag TAG           Image tag (default: latest)"
    echo "  --no-rm                 Don't remove container when stopped"
    echo
    echo "Environment Variables:"
    echo "  VNC_HOST               VNC host binding (overrides -H)"
    echo "  VNC_PORT               VNC web port (overrides -p)"
    echo "  VNC_BACKEND_HOST       VNC backend host (overrides -b)"
    echo "  VNC_BACKEND_PORT       VNC backend port (overrides -B)"
    echo "  CLOUDFLARE_TUNNEL      Enable Cloudflare Tunnel mode"
    echo
    echo "Examples:"
    echo "  # Basic localhost access"
    echo "  $0"
    echo
    echo "  # Subdomain access with custom ports"
    echo "  $0 -p 8080 -P 5901 -H 0.0.0.0"
    echo
    echo "  # Cloudflare Tunnel mode"
    echo "  CLOUDFLARE_TUNNEL=1 $0 -H 0.0.0.0"
    echo
    echo "  # With volume mount"
    echo "  $0 -v /path/to/data:/home/shared"
    echo
    echo "  # With resource limits"
    echo "  $0 -m 2g -c 1.5"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -d|--detach)
            DETACH="-d"
            shift
            ;;
        -n|--name)
            CONTAINER_NAME="$2"
            shift 2
            ;;
        -p|--port)
            VNC_PORT="$2"
            shift 2
            ;;
        -P|--client-port)
            VNC_CLIENT_PORT="$2"
            shift 2
            ;;
        -H|--host)
            VNC_HOST="$2"
            shift 2
            ;;
        -b|--backend-host)
            VNC_BACKEND_HOST="$2"
            shift 2
            ;;
        -B|--backend-port)
            VNC_BACKEND_PORT="$2"
            shift 2
            ;;
        -v|--volume)
            VOLUMES="$VOLUMES -v $2"
            shift 2
            ;;
        -m|--memory)
            MEMORY="--memory=$2"
            shift 2
            ;;
        -c|--cpus)
            CPUS="--cpus=$2"
            shift 2
            ;;
        -e|--env-file)
            ENV_FILE="--env-file $2"
            shift 2
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        --no-rm)
            RM=""
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Check if environment variables override command line options
VNC_HOST="${VNC_HOST:-0.0.0.0}"
VNC_PORT="${VNC_PORT:-6080}"
VNC_BACKEND_HOST="${VNC_BACKEND_HOST:-localhost}"
VNC_BACKEND_PORT="${VNC_BACKEND_PORT:-5900}"

# Set image tag
IMAGE_TAG="${IMAGE_TAG:-latest}"
FULL_IMAGE_NAME="$IMAGE_NAME:$IMAGE_TAG"

# Check if image exists
if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^$FULL_IMAGE_NAME$"; then
    print_warning "Image '$FULL_IMAGE_NAME' not found. Building..."
    docker build -t "$FULL_IMAGE_NAME" .
fi

# Check if container already exists
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
DOCKER_RUN_CMD="$DOCKER_RUN_CMD -p $VNC_HOST:$VNC_PORT:6080"
DOCKER_RUN_CMD="$DOCKER_RUN_CMD -p $VNC_HOST:$VNC_CLIENT_PORT:5900"
DOCKER_RUN_CMD="$DOCKER_RUN_CMD $VOLUMES"
DOCKER_RUN_CMD="$DOCKER_RUN_CMD $MEMORY"
DOCKER_RUN_CMD="$DOCKER_RUN_CMD $CPUS"

# Add environment variables
DOCKER_RUN_CMD="$DOCKER_RUN_CMD -e VNC_HOST=$VNC_HOST"
DOCKER_RUN_CMD="$DOCKER_RUN_CMD -e VNC_PORT=6080"
DOCKER_RUN_CMD="$DOCKER_RUN_CMD -e VNC_BACKEND_HOST=$VNC_BACKEND_HOST"
DOCKER_RUN_CMD="$DOCKER_RUN_CMD -e VNC_BACKEND_PORT=$VNC_BACKEND_PORT"

if [[ -n "$ENV_FILE" ]]; then
    DOCKER_RUN_CMD="$DOCKER_RUN_CMD $ENV_FILE"
fi

DOCKER_RUN_CMD="$DOCKER_RUN_CMD $FULL_IMAGE_NAME"

# Run the container
print_status "Starting container '$CONTAINER_NAME'..."
print_status "Image: $FULL_IMAGE_NAME"
print_status "VNC Web: http://localhost:$VNC_PORT"
print_status "VNC Client: localhost:$VNC_CLIENT_PORT"
print_status "Configuration:"
print_status "  VNC Host: $VNC_HOST"
print_status "  VNC Port: $VNC_PORT"
print_status "  Backend Host: $VNC_BACKEND_HOST"
print_status "  Backend Port: $VNC_BACKEND_PORT"

if eval $DOCKER_RUN_CMD; then
    print_success "Container started successfully!"
    
    if [[ -n "$DETACH" ]]; then
        print_status "Container is running in background."
        print_status "To view logs: docker logs $CONTAINER_NAME"
        print_status "To stop: docker stop $CONTAINER_NAME"
        print_status "To access shell: docker exec -it $CONTAINER_NAME bash"
    fi
    
    print_status "Access your VNC desktop at: http://localhost:$VNC_PORT"
    
    # Show Cloudflare Tunnel info if enabled
    if [[ "$CLOUDFLARE_TUNNEL" == "1" ]]; then
        echo
        print_status "Cloudflare Tunnel Mode Enabled:"
        print_status "  - Container is configured for Cloudflare Tunnel access"
        print_status "  - Use Cloudflare Tunnel to expose the service"
        print_status "  - WebSocket connections will work with any subdomain"
    fi
else
    print_error "Failed to start container!"
    exit 1
fi 