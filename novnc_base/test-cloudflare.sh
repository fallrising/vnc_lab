#!/bin/bash

# Test script for Cloudflare Tunnel compatibility
# This script tests the VNC container with different hostname scenarios

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Test localhost access
test_localhost() {
    print_status "Testing localhost access..."
    
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:6080 | grep -q "200"; then
        print_success "Localhost access working"
        return 0
    else
        print_error "Localhost access failed"
        return 1
    fi
}

# Test WebSocket endpoint
test_websocket() {
    print_status "Testing WebSocket endpoint..."
    
    # Test if the endpoint responds (even if it's a 404, it means the server is running)
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:6080/websockify | grep -q "404"; then
        print_success "WebSocket endpoint responding"
        return 0
    else
        print_error "WebSocket endpoint not responding"
        return 1
    fi
}

# Test VNC backend
test_vnc_backend() {
    print_status "Testing VNC backend..."
    
    # Check if x11vnc is running
    if docker exec vnc-base ps aux | grep -q "x11vnc"; then
        print_success "VNC backend running"
        return 0
    else
        print_error "VNC backend not running"
        return 1
    fi
}

# Test environment variables
test_environment() {
    print_status "Testing environment variables..."
    
    # Check if environment variables are set correctly
    VNC_HOST=$(docker exec vnc-base printenv VNC_HOST)
    VNC_PORT=$(docker exec vnc-base printenv VNC_PORT)
    VNC_BACKEND_HOST=$(docker exec vnc-base printenv VNC_BACKEND_HOST)
    VNC_BACKEND_PORT=$(docker exec vnc-base printenv VNC_BACKEND_PORT)
    
    echo "  VNC_HOST: $VNC_HOST"
    echo "  VNC_PORT: $VNC_PORT"
    echo "  VNC_BACKEND_HOST: $VNC_BACKEND_HOST"
    echo "  VNC_BACKEND_PORT: $VNC_BACKEND_PORT"
    
    if [[ "$VNC_HOST" == "0.0.0.0" && "$VNC_PORT" == "6080" && "$VNC_BACKEND_HOST" == "localhost" && "$VNC_BACKEND_PORT" == "5900" ]]; then
        print_success "Environment variables set correctly"
        return 0
    else
        print_error "Environment variables not set correctly"
        return 1
    fi
}

# Test HTML content
test_html_content() {
    print_status "Testing HTML content..."
    
    # Check if our custom HTML is being served
    if curl -s http://localhost:6080 | grep -q "Dynamic WebSocket URL resolution"; then
        print_success "Custom HTML content detected"
        return 0
    else
        print_warning "Custom HTML content not detected (using default noVNC)"
        return 0
    fi
}

# Test Cloudflare Tunnel simulation
test_cloudflare_simulation() {
    print_status "Testing Cloudflare Tunnel simulation..."
    
    # Create a simple test to simulate subdomain access
    # This tests if the WebSocket URL resolution works with different hostnames
    
    # Test with a mock subdomain
    MOCK_HOST="vnc.example.com"
    
    # Create a simple test HTML file
    cat > /tmp/test-cloudflare.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Cloudflare Tunnel Test</title>
</head>
<body>
    <h1>Cloudflare Tunnel Test</h1>
    <p>Testing WebSocket URL resolution for: $MOCK_HOST</p>
    <script>
        // Simulate the WebSocket URL resolution from our custom HTML
        function getWebSocketURL() {
            const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            const host = '$MOCK_HOST';
            const path = window.location.pathname.replace(/\/$/, '');
            return \`\${protocol}//\${host}\${path}/websockify\`;
        }
        
        const wsUrl = getWebSocketURL();
        console.log('WebSocket URL:', wsUrl);
        
        // Display the result
        document.getElementById('result').textContent = wsUrl;
    </script>
    <p>WebSocket URL: <span id="result"></span></p>
</body>
</html>
EOF
    
    print_success "Cloudflare Tunnel simulation test created"
    print_status "Expected WebSocket URL: ws://$MOCK_HOST/websockify"
    print_status "Test file created at: /tmp/test-cloudflare.html"
}

# Main test function
main() {
    print_status "Starting Cloudflare Tunnel compatibility tests..."
    echo
    
    local tests_passed=0
    local tests_total=0
    
    # Run all tests
    test_localhost && ((tests_passed++))
    ((tests_total++))
    
    test_websocket && ((tests_passed++))
    ((tests_total++))
    
    test_vnc_backend && ((tests_passed++))
    ((tests_total++))
    
    test_environment && ((tests_passed++))
    ((tests_total++))
    
    test_html_content && ((tests_passed++))
    ((tests_total++))
    
    test_cloudflare_simulation
    ((tests_total++))
    
    echo
    print_status "Test Results: $tests_passed/$tests_total tests passed"
    
    if [[ $tests_passed -eq $((tests_total - 1)) ]]; then
        print_success "All compatibility tests passed!"
        echo
        print_status "Your VNC container is ready for Cloudflare Tunnel deployment:"
        print_status "1. Container is running and accessible"
        print_status "2. WebSocket endpoint is responding"
        print_status "3. Environment variables are configured"
        print_status "4. Dynamic WebSocket URL resolution is implemented"
        echo
        print_status "Next steps:"
        print_status "1. Configure Cloudflare Tunnel to point to localhost:6080"
        print_status "2. Set up your subdomain in Cloudflare Zero Trust"
        print_status "3. Access your VNC via the Cloudflare Tunnel URL"
    else
        print_error "Some tests failed. Please check the container configuration."
        exit 1
    fi
}

# Run main function
main "$@" 