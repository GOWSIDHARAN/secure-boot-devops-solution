#!/bin/bash

set -e  # Exit on any error

echo "🚀 Starting Secure Boot Challenge Setup..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    command -v docker >/dev/null 2>&1 || { print_error "Docker is required but not installed. Aborting."; exit 1; }
    command -v kubectl >/dev/null 2>&1 || { print_error "kubectl is required but not installed. Aborting."; exit 1; }
    command -v helm >/dev/null 2>&1 || { print_error "Helm is required but not installed. Aborting."; exit 1; }
    command -v terraform >/dev/null 2>&1 || { print_error "Terraform is required but not installed. Aborting."; exit 1; }
    
    print_status "All prerequisites are installed!"
}

# Build Docker image
build_docker_image() {
    print_status "Building Docker image..."
    docker build -t secure-boot-app:latest .
    print_status "Docker image built successfully!"
}

# Initialize and apply Terraform
apply_terraform() {
    print_status "Initializing Terraform..."
    cd terraform
    terraform init
    print_status "Applying Terraform configuration..."
    terraform apply -auto-approve
    cd ..
    print_status "Terraform configuration applied successfully!"
}

# Install or upgrade Helm release
deploy_helm_chart() {
    print_status "Deploying Helm chart..."
    
    # Check if release exists
    if helm status secure-boot-app -n devops-challenge >/dev/null 2>&1; then
        print_status "Upgrading existing Helm release..."
        helm upgrade secure-boot-app helm/ -n devops-challenge --set image.tag=latest
    else
        print_status "Installing new Helm release..."
        helm install secure-boot-app helm/ -n devops-challenge --set image.tag=latest
    fi
    
    print_status "Helm chart deployed successfully!"
}

# Wait for deployment to be ready
wait_for_deployment() {
    print_status "Waiting for deployment to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/secure-boot-app -n devops-challenge
    print_status "Deployment is ready!"
}

# Main execution
main() {
    print_status "Starting deployment process..."
    
    check_prerequisites
    build_docker_image
    apply_terraform
    deploy_helm_chart
    wait_for_deployment
    
    print_status "🎉 Setup completed successfully!"
    print_status "You can now run ./system-checks.sh to validate the deployment."
}

# Run main function
main
