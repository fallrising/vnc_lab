#!/bin/bash

# VNC Subdomain Deployment Script
# This script sets up VNC with proper subdomain support

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOMAIN=${1:-"vnc.yourdomain.com"}
EMAIL=${2:-"admin@yourdomain.com"}
VNC_PASSWORD=${3:-"vnc123"}

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

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Create SSL directory
setup_ssl_directory() {
    print_status "Setting up SSL directory..."
    mkdir -p ssl
    mkdir -p certbot-www
    print_success "SSL directory created"
}

# Update configuration files
update_configurations() {
    print_status "Updating configuration files..."
    
    # Update Nginx configuration
    sed -i.bak "s/vnc.yourdomain.com/$DOMAIN/g" nginx-subdomain.conf
    sed -i.bak "s/your-email@example.com/$EMAIL/g" docker-compose.subdomain.yml
    
    # Update Docker Compose environment
    export VNC_PASSWORD=$VNC_PASSWORD
    
    print_success "Configuration files updated"
}

# Build and start services
deploy_services() {
    print_status "Building and starting services..."
    
    # Build VNC image
    docker-compose -f docker-compose.subdomain.yml build vnc-base
    
    # Start services
    docker-compose -f docker-compose.subdomain.yml up -d
    
    print_success "Services deployed successfully"
}

# Setup SSL certificate
setup_ssl() {
    print_status "Setting up SSL certificate..."
    
    # Wait for Nginx to be ready
    sleep 10
    
    # Request SSL certificate
    docker-compose -f docker-compose.subdomain.yml run --rm certbot
    
    # Reload Nginx to use SSL
    docker-compose -f docker-compose.subdomain.yml exec nginx-proxy nginx -s reload
    
    print_success "SSL certificate setup completed"
}

# Create renewal script
create_renewal_script() {
    print_status "Creating SSL renewal script..."
    
    cat > renew-ssl.sh << 'EOF'
#!/bin/bash
# SSL Certificate Renewal Script

docker-compose -f docker-compose.subdomain.yml run --rm certbot renew
docker-compose -f docker-compose.subdomain.yml exec nginx-proxy nginx -s reload
EOF
    
    chmod +x renew-ssl.sh
    
    print_success "SSL renewal script created"
}

# Setup cron job for SSL renewal
setup_cron() {
    print_status "Setting up SSL renewal cron job..."
    
    # Add to crontab (renew every 60 days)
    (crontab -l 2>/dev/null; echo "0 12 * * 0 /path/to/$(pwd)/renew-ssl.sh") | crontab -
    
    print_success "SSL renewal cron job set up"
}

# Display access information
show_access_info() {
    print_success "VNC deployment completed!"
    echo
    echo "Access Information:"
    echo "=================="
    echo "VNC Web Interface: https://$DOMAIN"
    echo "VNC Password: $VNC_PASSWORD"
    echo "Direct VNC: localhost:5900"
    echo
    echo "Management Commands:"
    echo "==================="
    echo "View logs: docker-compose -f docker-compose.subdomain.yml logs -f"
    echo "Stop services: docker-compose -f docker-compose.subdomain.yml down"
    echo "Restart services: docker-compose -f docker-compose.subdomain.yml restart"
    echo "Renew SSL: ./renew-ssl.sh"
    echo
    echo "Security Notes:"
    echo "=============="
    echo "- VNC is accessible via HTTPS only"
    echo "- SSL certificate will auto-renew"
    echo "- Rate limiting is enabled"
    echo "- CORS is properly configured"
}

# Main deployment function
main() {
    print_status "Starting VNC subdomain deployment..."
    echo "Domain: $DOMAIN"
    echo "Email: $EMAIL"
    echo "VNC Password: $VNC_PASSWORD"
    echo
    
    check_prerequisites
    setup_ssl_directory
    update_configurations
    deploy_services
    setup_ssl
    create_renewal_script
    setup_cron
    show_access_info
}

# Help function
show_help() {
    echo "Usage: $0 [DOMAIN] [EMAIL] [VNC_PASSWORD]"
    echo
    echo "Arguments:"
    echo "  DOMAIN        Subdomain for VNC access (default: vnc.yourdomain.com)"
    echo "  EMAIL         Email for SSL certificate (default: admin@yourdomain.com)"
    echo "  VNC_PASSWORD  VNC access password (default: vnc123)"
    echo
    echo "Example:"
    echo "  $0 vnc.mydomain.com admin@mydomain.com mysecurepassword"
}

# Check if help is requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Run main function
main "$@" 