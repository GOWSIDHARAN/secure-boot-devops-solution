#!/bin/bash

set -e

echo "🔍 Running System Checks for Play with Docker..."

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

# Get container name/id
get_container() {
    CONTAINER=$(docker-compose ps -q secure-boot-app)
    if [ -z "$CONTAINER" ]; then
        echo "❌ Container not found. Please run ./play-with-docker-setup.sh first."
        exit 1
    fi
    echo $CONTAINER
}

# Check 1: User UID verification
check_user_uid() {
    print_header "Check 1: User UID inside container"
    CONTAINER=$(get_container)
    
    print_status "Container ID: $CONTAINER"
    
    USER_UID=$(docker exec $CONTAINER id -u)
    print_status "User UID: $USER_UID"
    
    if [ "$USER_UID" = "0" ]; then
        print_status "❌ Container is running as root (UID 0)!"
        return 1
    else
        print_status "✅ Container is running as non-root user (UID $USER_UID)!"
    fi
}

# Check 2: Port binding verification
check_port_binding() {
    print_header "Check 2: Port binding inside container"
    CONTAINER=$(get_container)
    
    print_status "Checking port binding inside container..."
    docker exec $CONTAINER netstat -tlnp 2>/dev/null || \
    docker exec $CONTAINER ss -tlnp 2>/dev/null || \
    print_status "Checking processes instead..."
    
    print_status "Running processes:"
    docker exec $CONTAINER ps aux
}

# Check 3: API response validation
check_api_response() {
    print_header "Check 3: API Response Validation"
    
    print_status "Testing API response on port 3000..."
    RESPONSE=$(curl -s http://localhost:3000/ 2>/dev/null || echo "")
    
    if [ -z "$RESPONSE" ]; then
        print_status "❌ Failed to get response from API!"
    else
        print_status "API Response: $RESPONSE"
        
        # Validate JSON structure
        echo "$RESPONSE" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print('✅ Response is valid JSON!')
    if data.get('message') == 'Hello, Candidate' and data.get('version') == '1.0.0':
        print('✅ API response content is correct!')
    else:
        print('❌ API response content is incorrect!')
        print(f'Expected: message=\"Hello, Candidate\", version=\"1.0.0\"')
        print(f'Got: message=\"{data.get(\"message\", \"\")}\", version=\"{data.get(\"version\", \"\")}\"')
except:
    print('❌ Response is not valid JSON!')
"
    fi
}

# Additional security checks
check_security_context() {
    print_header "Additional Security Checks"
    CONTAINER=$(get_container)
    
    print_status "Checking container capabilities..."
    docker exec $CONTAINER capsh --print | grep -E "(Current|Bounding)" || print_status "Capabilities info available"
    
    print_status "Checking filesystem permissions..."
    docker exec $CONTAINER ls -la /app
    
    print_status "Checking if filesystem is read-only..."
    docker exec $CONTAINER touch /test-write 2>/dev/null && \
    (docker exec $CONTAINER rm /test-write 2>/dev/null; print_status "❌ Filesystem is writable!") || \
    print_status "✅ Filesystem is read-only (as expected)!"
}

# Show container details
show_container_details() {
    print_header "Container Details"
    CONTAINER=$(get_container)
    
    print_status "Container info:"
    docker inspect $CONTAINER --format='{{.Name}} - {{.State.Status}} - {{.Config.User}}'
    
    print_status "Container security settings:"
    docker inspect $CONTAINER --format='{{json .HostConfig.CapAdd}}' | python3 -c "import sys, json; caps=json.load(sys.stdin); print(f'Capabilities: {caps}')"
    
    print_status "Recent logs:"
    docker logs --tail=10 $CONTAINER
}

# Main execution
main() {
    print_status "Starting Play with Docker system validation checks..."
    
    check_user_uid
    check_port_binding
    check_api_response
    check_security_context
    show_container_details
    
    print_status "🎉 System checks completed!"
}

# Run main function
main
