#!/bin/bash

set -e  # Exit on any error

echo "🔍 Running System Checks for Secure Boot Challenge..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Check if deployment exists
check_deployment() {
    print_status "Checking if deployment exists..."
    if ! kubectl get deployment secure-boot-app -n devops-challenge >/dev/null 2>&1; then
        print_error "Deployment not found. Please run setup.sh first."
        exit 1
    fi
    print_status "Deployment found!"
}

# Get pod name
get_pod_name() {
    POD_NAME=$(kubectl get pods -n devops-challenge -l app.kubernetes.io/name=secure-boot-app -o jsonpath='{.items[0].metadata.name}')
    if [ -z "$POD_NAME" ]; then
        print_error "No running pod found!"
        exit 1
    fi
    echo $POD_NAME
}

# Check 1: Print UID of user running inside container
check_user_uid() {
    print_header "Check 1: User UID inside container"
    POD_NAME=$(get_pod_name)
    print_status "Pod name: $POD_NAME"
    
    print_status "Checking user UID inside container..."
    USER_UID=$(kubectl exec -n devops-challenge $POD_NAME -- id -u)
    print_status "User UID: $USER_UID"
    
    if [ "$USER_UID" = "0" ]; then
        print_error "❌ Container is running as root (UID 0)!"
        return 1
    else
        print_status "✅ Container is running as non-root user (UID $USER_UID)!"
    fi
}

# Check 2: Show which port the application process is bound to
check_port_binding() {
    print_header "Check 2: Port binding inside container"
    POD_NAME=$(get_pod_name)
    
    print_status "Checking port binding inside container..."
    kubectl exec -n devops-challenge $POD_NAME -- netstat -tlnp 2>/dev/null || \
    kubectl exec -n devops-challenge $POD_NAME -- ss -tlnp 2>/dev/null || \
    print_warning "Could not check port binding with netstat/ss, trying ps..."
    
    print_status "Running processes:"
    kubectl exec -n devops-challenge $POD_NAME -- ps aux
}

# Check 3: Execute curl request to validate JSON response
check_api_response() {
    print_header "Check 3: API Response Validation"
    
    print_status "Setting up port forwarding..."
    kubectl port-forward -n devops-challenge service/secure-boot-app 8080:80 &
    PORT_FORWARD_PID=$!
    
    # Wait for port forward to be ready
    sleep 3
    
    print_status "Testing API response..."
    RESPONSE=$(curl -s http://localhost:8080/ 2>/dev/null || echo "")
    
    if [ -z "$RESPONSE" ]; then
        print_error "❌ Failed to get response from API!"
    else
        print_status "API Response: $RESPONSE"
        
        # Validate JSON structure
        echo "$RESPONSE" | python3 -m json.tool >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            print_status "✅ Response is valid JSON!"
            
            # Check if message and version are correct
            MESSAGE=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('message', ''))")
            VERSION=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('version', ''))")
            
            if [ "$MESSAGE" = "Hello, Candidate" ] && [ "$VERSION" = "1.0.0" ]; then
                print_status "✅ API response is correct!"
            else
                print_error "❌ API response content is incorrect!"
                print_error "Expected message: 'Hello, Candidate', got: '$MESSAGE'"
                print_error "Expected version: '1.0.0', got: '$VERSION'"
            fi
        else
            print_error "❌ Response is not valid JSON!"
        fi
    fi
    
    # Clean up port forwarding
    kill $PORT_FORWARD_PID 2>/dev/null || true
}

# Additional checks
check_security_context() {
    print_header "Additional Security Checks"
    POD_NAME=$(get_pod_name)
    
    print_status "Checking security context..."
    kubectl get pod $POD_NAME -n devops-challenge -o jsonpath='{.spec.securityContext}' | python3 -m json.tool || \
    print_status "Security context info available via kubectl describe"
    
    print_status "Checking container security context..."
    kubectl get pod $POD_NAME -n devops-challenge -o jsonpath='{.spec.containers[0].securityContext}' | python3 -m json.tool || \
    print_status "Container security context info available via kubectl describe"
}

# Show pod status and logs
show_pod_status() {
    print_header "Pod Status and Logs"
    POD_NAME=$(get_pod_name)
    
    print_status "Pod status:"
    kubectl get pod $POD_NAME -n devops-challenge -o wide
    
    print_status "Recent logs:"
    kubectl logs $POD_NAME -n devops-challenge --tail=10
}

# Main execution
main() {
    print_status "Starting system validation checks..."
    
    check_deployment
    check_user_uid
    check_port_binding
    check_api_response
    check_security_context
    show_pod_status
    
    print_status "🎉 System checks completed!"
}

# Run main function
main
