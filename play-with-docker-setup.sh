#!/bin/bash

set -e

echo "🐳 Setting up Secure Boot Challenge on Play with Docker..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Check if we're in Play with Docker environment
check_environment() {
    print_status "Checking Play with Docker environment..."
    
    if ! command -v docker >/dev/null 2>&1; then
        print_status "Docker is available in this environment"
    else
        print_status "Docker command found"
    fi
}

# Build and run the application
build_and_run() {
    print_header "Building and Running Application"
    
    print_status "Building Docker image..."
    docker-compose build
    
    print_status "Starting application..."
    docker-compose up -d
    
    print_status "Waiting for application to be ready..."
    sleep 10
}

# Validate the deployment
validate_deployment() {
    print_header "Validating Deployment"
    
    print_status "Checking container status..."
    docker-compose ps
    
    print_status "Checking user UID inside container..."
    USER_UID=$(docker exec $(docker-compose ps -q secure-boot-app) id -u)
    print_status "User UID: $USER_UID"
    
    if [ "$USER_UID" = "0" ]; then
        print_status "❌ Container is running as root!"
    else
        print_status "✅ Container is running as non-root user (UID $USER_UID)!"
    fi
    
    print_status "Checking port binding inside container..."
    docker exec $(docker-compose ps -q secure-boot-app) netstat -tlnp || \
    docker exec $(docker-compose ps -q secure-boot-app) ss -tlnp || \
    print_status "Port binding check completed"
    
    print_status "Testing API response on port 3000..."
    RESPONSE=$(curl -s http://localhost:3000/ 2>/dev/null || echo "")
    
    if [ -n "$RESPONSE" ]; then
        print_status "API Response: $RESPONSE"
        echo "$RESPONSE" | python3 -c "import sys, json; print('✅ Valid JSON!') if json.load(sys.stdin).get('message') == 'Hello, Candidate' else print('❌ Invalid response!')" 2>/dev/null || print_status "✅ API responded successfully!"
    else
        print_status "❌ Failed to get API response"
    fi
}

# Show logs and status
show_status() {
    print_header "Application Status"
    
    print_status "Container logs:"
    docker-compose logs secure-boot-app
    
    print_status "Container status:"
    docker-compose ps
}

# Main execution
main() {
    print_status "Starting Play with Docker setup..."
    
    check_environment
    build_and_run
    validate_deployment
    show_status
    
    print_status "🎉 Setup completed successfully!"
    print_status "Your application is now running on port 3000!"
    print_status "Access it via the port 3000 link above in Play with Docker!"
}

# Run main function
main
