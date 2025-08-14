#!/bin/bash

# VNC Lab - Management Script
# Unified management script for all VNC containers

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONTAINERS=("novnc_base" "novnc_cursor" "novnc_llm_cli" "novnc_tool" "novnc_warp")

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
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  build [container]       Build image for specified container (or all)"
    echo "  run [container]         Run container for specified container (or all)"
    echo "  push [container]        Push image for specified container (or all)"
    echo "  export [container]      Export image for specified container (or all)"
    echo "  import [container]      Import image for specified container (or all)"
    echo "  clean [container]       Clean resources for specified container (or all)"
    echo "  status                  Show status of all containers"
    echo "  logs [container]        Show logs for specified container"
    echo "  stop [container]        Stop specified container (or all)"
    echo "  start [container]       Start specified container (or all)"
    echo "  restart [container]     Restart specified container (or all)"
    echo ""
    echo "Available containers:"
    for container in "${CONTAINERS[@]}"; do
        echo "  $container"
    done
    echo "  all                     # All containers"
    echo ""
    echo "Examples:"
    echo "  $0 build all            # Build all containers"
    echo "  $0 run novnc_cursor     # Run Cursor IDE container"
    echo "  $0 run novnc_warp       # Run Warp terminal container"
    echo "  $0 run novnc_llm_cli    # Run AI tools container"
    echo "  $0 status               # Show all container status"
    echo "  $0 clean all            # Clean all resources"
}

# Function to check if container is valid
is_valid_container() {
    local container=$1
    if [[ "$container" == "all" ]]; then
        return 0
    fi
    
    for valid_container in "${CONTAINERS[@]}"; do
        if [[ "$container" == "$valid_container" ]]; then
            return 0
        fi
    done
    return 1
}

# Function to get containers to process
get_containers_to_process() {
    local container=$1
    if [[ "$container" == "all" ]]; then
        echo "${CONTAINERS[@]}"
    else
        echo "$container"
    fi
}

# Function to build container
build_container() {
    local container=$1
    print_status "Building $container..."
    
    # Check dependencies
    if [[ "$container" == "novnc_cursor" || "$container" == "novnc_warp" ]]; then
        if ! docker images "novnc-base:latest" | grep -q "novnc-base"; then
            print_error "Base image 'novnc-base:latest' not found!"
            print_status "Please build the base image first:"
            print_status "  ./manage.sh build novnc_base"
            return 1
        fi
    fi
    
    if [[ -d "$container" ]]; then
        cd "$container"
        if [[ -f "build.sh" ]]; then
            if ./build.sh; then
                print_success "Built $container successfully"
            else
                print_error "Failed to build $container"
                return 1
            fi
        else
            print_error "build.sh not found in $container"
            return 1
        fi
        cd ..
    else
        print_error "Container directory $container not found"
        return 1
    fi
}

# Function to run container
run_container() {
    local container=$1
    print_status "Running $container..."
    
    if [[ -d "$container" ]]; then
        cd "$container"
        if [[ -f "run.sh" ]]; then
            if ./run.sh; then
                print_success "Started $container successfully"
            else
                print_error "Failed to start $container"
                return 1
            fi
        else
            print_error "run.sh not found in $container"
            return 1
        fi
        cd ..
    else
        print_error "Container directory $container not found"
        return 1
    fi
}

# Function to push container
push_container() {
    local container=$1
    print_status "Pushing $container..."
    
    if [[ -d "$container" ]]; then
        cd "$container"
        if [[ -f "push.sh" ]]; then
            if ./push.sh; then
                print_success "Pushed $container successfully"
            else
                print_error "Failed to push $container"
                return 1
            fi
        else
            print_error "push.sh not found in $container"
            return 1
        fi
        cd ..
    else
        print_error "Container directory $container not found"
        return 1
    fi
}

# Function to export container
export_container() {
    local container=$1
    print_status "Exporting $container..."
    
    if [[ -d "$container" ]]; then
        cd "$container"
        if [[ -f "export.sh" ]]; then
            if ./export.sh; then
                print_success "Exported $container successfully"
            else
                print_error "Failed to export $container"
                return 1
            fi
        else
            print_error "export.sh not found in $container"
            return 1
        fi
        cd ..
    else
        print_error "Container directory $container not found"
        return 1
    fi
}

# Function to import container
import_container() {
    local container=$1
    print_status "Importing $container..."
    
    if [[ -d "$container" ]]; then
        cd "$container"
        if [[ -f "import.sh" ]]; then
            if ./import.sh; then
                print_success "Imported $container successfully"
            else
                print_error "Failed to import $container"
                return 1
            fi
        else
            print_error "import.sh not found in $container"
            return 1
        fi
        cd ..
    else
        print_error "Container directory $container not found"
        return 1
    fi
}

# Function to clean container
clean_container() {
    local container=$1
    print_status "Cleaning $container..."
    
    if [[ -d "$container" ]]; then
        cd "$container"
        if [[ -f "clean.sh" ]]; then
            if ./clean.sh; then
                print_success "Cleaned $container successfully"
            else
                print_error "Failed to clean $container"
                return 1
            fi
        else
            print_error "clean.sh not found in $container"
            return 1
        fi
        cd ..
    else
        print_error "Container directory $container not found"
        return 1
    fi
}

# Function to show status
show_status() {
    print_status "Container Status:"
    echo ""
    
    for container in "${CONTAINERS[@]}"; do
        echo "=== $container ==="
        
        # Check if container is running
        CONTAINER_NAME=""
        case $container in
            "novnc_base")
                CONTAINER_NAME="novnc-base-container"
                ;;
            "novnc_cursor")
                CONTAINER_NAME="novnc-cursor-container"
                ;;
            "novnc_llm_cli")
                CONTAINER_NAME="novnc-llm-cli-container"
                ;;
            "novnc_tool")
                CONTAINER_NAME="novnc-tool-container"
                ;;
            "novnc_warp")
                CONTAINER_NAME="novnc-warp-container"
                ;;
        esac
        
        if docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -q "$CONTAINER_NAME"; then
            docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        else
            echo "Container not running"
        fi
        
        # Check if image exists
        IMAGE_NAME=""
        case $container in
            "novnc_base")
                IMAGE_NAME="novnc-base"
                ;;
            "novnc_cursor")
                IMAGE_NAME="novnc-cursor"
                ;;
            "novnc_llm_cli")
                IMAGE_NAME="novnc-llm-cli"
                ;;
            "novnc_tool")
                IMAGE_NAME="novnc-tool"
                ;;
            "novnc_warp")
                IMAGE_NAME="novnc-warp"
                ;;
        esac
        
        if docker images "$IMAGE_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep -q "$IMAGE_NAME"; then
            echo "Images:"
            docker images "$IMAGE_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
        else
            echo "No images found"
        fi
        
        echo ""
    done
}

# Function to show logs
show_logs() {
    local container=$1
    local container_name=""
    
    case $container in
        "novnc_base")
            container_name="novnc-base-container"
            ;;
        "novnc_cursor")
            container_name="novnc-cursor-container"
            ;;
        "novnc_llm_cli")
            container_name="novnc-llm-cli-container"
            ;;
        "novnc_tool")
            container_name="novnc-tool-container"
            ;;
        "novnc_warp")
            container_name="novnc-warp-container"
            ;;
    esac
    
    if docker ps --filter "name=$container_name" --format "{{.Names}}" | grep -q "$container_name"; then
        print_status "Showing logs for $container_name:"
        docker logs "$container_name"
    else
        print_warning "Container $container_name is not running"
    fi
}

# Function to stop container
stop_container() {
    local container=$1
    local container_name=""
    
    case $container in
        "novnc_base")
            container_name="novnc-base-container"
            ;;
        "novnc_cursor")
            container_name="novnc-cursor-container"
            ;;
        "novnc_llm_cli")
            container_name="novnc-llm-cli-container"
            ;;
        "novnc_tool")
            container_name="novnc-tool-container"
            ;;
        "novnc_warp")
            container_name="novnc-warp-container"
            ;;
    esac
    
    if docker ps --filter "name=$container_name" --format "{{.Names}}" | grep -q "$container_name"; then
        print_status "Stopping $container_name..."
        docker stop "$container_name"
        print_success "Stopped $container_name"
    else
        print_warning "Container $container_name is not running"
    fi
}

# Function to start container
start_container() {
    local container=$1
    print_status "Starting $container..."
    run_container "$container"
}

# Function to restart container
restart_container() {
    local container=$1
    print_status "Restarting $container..."
    stop_container "$container"
    sleep 2
    start_container "$container"
}

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running or not accessible!"
    exit 1
fi

# Parse command line arguments
if [[ $# -eq 0 ]]; then
    show_usage
    exit 0
fi

COMMAND=$1
shift

case $COMMAND in
    build|run|push|export|import|clean|logs|stop|start|restart)
        if [[ $# -eq 0 ]]; then
            print_error "Please specify a container or 'all'"
            show_usage
            exit 1
        fi
        
        CONTAINER=$1
        
        if ! is_valid_container "$CONTAINER"; then
            print_error "Invalid container: $CONTAINER"
            show_usage
            exit 1
        fi
        
        CONTAINERS_TO_PROCESS=$(get_containers_to_process "$CONTAINER")
        
        case $COMMAND in
            build)
                for container in $CONTAINERS_TO_PROCESS; do
                    build_container "$container"
                done
                ;;
            run)
                for container in $CONTAINERS_TO_PROCESS; do
                    run_container "$container"
                done
                ;;
            push)
                for container in $CONTAINERS_TO_PROCESS; do
                    push_container "$container"
                done
                ;;
            export)
                for container in $CONTAINERS_TO_PROCESS; do
                    export_container "$container"
                done
                ;;
            import)
                for container in $CONTAINERS_TO_PROCESS; do
                    import_container "$container"
                done
                ;;
            clean)
                for container in $CONTAINERS_TO_PROCESS; do
                    clean_container "$container"
                done
                ;;
            logs)
                if [[ "$CONTAINER" == "all" ]]; then
                    print_error "Cannot show logs for all containers at once"
                    exit 1
                fi
                show_logs "$CONTAINER"
                ;;
            stop)
                for container in $CONTAINERS_TO_PROCESS; do
                    stop_container "$container"
                done
                ;;
            start)
                for container in $CONTAINERS_TO_PROCESS; do
                    start_container "$container"
                done
                ;;
            restart)
                for container in $CONTAINERS_TO_PROCESS; do
                    restart_container "$container"
                done
                ;;
        esac
        ;;
    status)
        show_status
        ;;
    *)
        print_error "Unknown command: $COMMAND"
        show_usage
        exit 1
        ;;
esac 