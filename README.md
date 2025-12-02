# Secure Boot Initiative - DevOps Engineering Challenge

## Overview

This repository contains a complete DevOps solution for the Secure Boot Challenge, demonstrating containerization, infrastructure as code, deployment automation, and security best practices. The solution addresses the critical security constraint of running containers as non-root users while binding to privileged ports.

## Architecture

- **Application**: Flask API running on port 80
- **Containerization**: Docker with non-root user execution
- **Infrastructure**: Kubernetes with Terraform provisioning
- **Deployment**: Helm charts with security configurations
- **Automation**: CI/CD pipeline and setup scripts
- **Validation**: Comprehensive system checks

## Prerequisites

Before running this solution, ensure you have the following tools installed:

### Required Tools
- **Docker** (v20.10+): For container image building
- **kubectl** (v1.25+): For Kubernetes cluster interaction
- **Helm** (v3.12+): For Helm chart deployment
- **Terraform** (v1.5+): For infrastructure provisioning
- **Python** (v3.11+): For local testing and validation scripts
- **curl**: For API testing

### Kubernetes Cluster Options
Choose one of the following local Kubernetes solutions:

1. **Play with Docker (Recommended for this challenge)**
   - Go to https://labs.play-with-docker.com/
   - Sign in with Docker Hub account
   - Use the provided scripts for setup

2. **Minikube** (Recommended for beginners)
   ```bash
   minikube start --cpus=2 --memory=2048
   ```

3. **Kind** (Kubernetes in Docker)
   ```bash
   kind create cluster --config kind-config.yaml
   ```

4. **Docker Desktop** (with Kubernetes enabled)
   - Enable Kubernetes in Docker Desktop settings

## Quick Start

### Option A: Play with Docker (Easiest - No Installation Required)

### Play with Docker (PWD) Configuration

### Why Port 8080 in PWD?

Play with Docker (PWD) has specific security restrictions that affect how containers can bind to ports:

1. **NET_BIND_SERVICE Limitation**:
   - PWD doesn't allow the `NET_BIND_SERVICE` capability for security reasons
   - This prevents binding to privileged ports (<1024) as a non-root user

2. **Port 8080 Solution**:
   - We use port 8080 inside the container (unprivileged port)
   - Map host port 3000 to container port 8080
   - This works around PWD's restrictions while maintaining security

3. **Security Maintained**:
   - Still runs as non-root user (UID 1000)
   - All other security measures remain in place
   - Only the port binding approach is modified

### PWD Setup Instructions

1. **Go to https://labs.play-with-docker.com/**
2. **Sign in** with your Docker Hub account
3. **Upload your files** or copy-paste the code
4. **Run the setup**:
   ```bash
   chmod +x play-with-docker-setup.sh play-with-docker-checks.sh
   ./play-with-docker-setup.sh
   ```
5. **Access the application**:
   - Click the port 3000 link that appears at the top of the PWD interface
   - This maps to port 8080 inside the container

6. **Verify the deployment**:
   ```bash
   ./play-with-docker-checks.sh
   ```

### Comparison: PWD vs Production

| Environment | Internal Port | Host Port | Capabilities Used |
|-------------|---------------|-----------|-------------------|
| **PWD**     | 8080          | 3000      | None (restricted) |
| **Production** | 80         | 80        | NET_BIND_SERVICE  |

In a production environment with proper permissions, the application runs on port 80 using the `NET_BIND_SERVICE` capability. PWD's security model requires this alternative configuration.

### Option B: Local Kubernetes Setup

1. **Clone and Setup**
```bash
git clone <repository-url>
cd secure-boot-challenge
chmod +x setup.sh system-checks.sh
```

2. **Deploy the Application**
```bash
./setup.sh
```

3. **Validate the Deployment**
```bash
./system-checks.sh
```

4. **Step 5: Access Your Application**
```bash
# Option 1: Port forwarding
kubectl port-forward -n devops-challenge service/secure-boot-app 8080:80
# Then visit: http://localhost:8080/

# Option 2: Use Minikube service
minikube service secure-boot-app -n devops-challenge --url
curl <node-ip>:30080/
```

**Note**: The application binds to port 80 inside the container using NET_BIND_SERVICE capability for non-root execution.

## The Port 80 vs. Non-Root Challenge

### The Problem
Standard Linux security prevents non-root users (UID > 0) from binding to ports below 1024. This creates a conflict with our requirements:
- **Security Constraint**: Container must run as non-root user
- **Application Requirement**: Must bind to port 80

### The Solution
I implemented a two-layer approach to solve this challenge:

#### 1. Container-Level Solution (Linux Capabilities)
In the Docker container, we use the `NET_BIND_SERVICE` capability:
```yaml
securityContext:
  capabilities:
    add:
      - NET_BIND_SERVICE
```

This capability allows non-root users to bind to privileged ports without full root privileges.

#### 2. Kubernetes-Level Solution
The Helm chart configures the same capability at both pod and container levels:
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true
  capabilities:
    add:
      - NET_BIND_SERVICE
```

### Security Benefits
- **Non-root execution**: Container runs as UID 1000, not root (UID 0)
- **Minimal privileges**: Only the specific capability needed for port binding
- **Read-only filesystem**: Prevents unauthorized modifications
- **Resource limits**: Memory constraints prevent resource exhaustion

## Project Structure

```
/
├── app/                          # Python application source code
│   ├── main.py                   # Flask API application
│   └── requirements.txt          # Python dependencies
├── helm/                         # Helm chart directory
│   ├── Chart.yaml               # Helm chart metadata
│   ├── values.yaml              # Default configuration values
│   └── templates/               # Kubernetes manifest templates
│       ├── deployment.yaml      # Deployment configuration
│       ├── service.yaml         # Service configuration
│       └── _helpers.tpl         # Template helpers
├── terraform/                   # Terraform configuration files
│   └── main.tf                  # Kubernetes resources
├── .github/workflows/           # CI pipeline configuration
│   └── ci.yml                   # GitHub Actions workflow
├── Dockerfile                   # Container definition
├── setup.sh                     # Local deployment automation
├── system-checks.sh             # Verification script
└── README.md                    # Documentation
```

## Detailed Components

### Application (Python & Docker)

#### Flask API
- **Framework**: Flask 2.3.3
- **Port**: 80 (configurable via PORT environment variable)
- **Response**: JSON with message and version
- **Endpoint**: `GET /` returns `{"message": "Hello, Candidate", "version": "1.0.0"}`

#### Docker Configuration
- **Base Image**: `python:3.11-alpine` (lightweight Alpine)
- **User**: `appuser` with UID/GID 1000
- **Security**: Non-root execution with minimal capabilities

### Infrastructure as Code (Terraform)

#### Kubernetes Resources
- **Namespace**: `devops-challenge`
- **ResourceQuota**: 512Mi memory limit
- **Provider**: Uses local `~/.kube/config`

### Deployment (Helm)

#### Security Features
- **Read-only filesystem**: `readOnlyRootFilesystem: true`
- **Non-root execution**: `runAsUser: 1000`
- **Capabilities**: `NET_BIND_SERVICE` for port 80 binding
- **Temporary volume**: `/tmp` mounted for runtime requirements

#### Service Configuration
- **Type**: NodePort (for local access)
- **Port**: 80 (container)
- **NodePort**: 30080 (external access)

### Automation (CI/CD)

#### GitHub Actions Pipeline
- **Python Linting**: flake8 code quality checks
- **Helm Linting**: chart validation
- **Terraform Validation**: syntax and format checks
- **Docker Build**: image creation (no push required)

#### Local Setup Script
- **Automated deployment**: Single-command setup
- **Error handling**: Graceful failure management
- **Progress tracking**: Colored output and status updates

### Validation (System Checks)

The `system-checks.sh` script performs comprehensive validation:

1. **User UID Verification**: Confirms non-root execution
2. **Port Binding Check**: Validates port 80 binding
3. **API Response Testing**: Confirms correct JSON output
4. **Security Context Review**: Validates security configurations
5. **Pod Status Monitoring**: Shows deployment health

## Security Best Practices Implemented

### Container Security
- **Non-root user execution** (UID 1000)
- **Read-only filesystem**
- **Minimal base image** (Alpine Linux)
- **Least privilege capabilities** (only NET_BIND_SERVICE)

### Kubernetes Security
- **Resource limits** (memory constraints)
- **Namespace isolation**
- **Security context configuration**
- **Read-only root filesystem**

### Infrastructure Security
- **Infrastructure as Code** (reproducible, auditable)
- **Resource quotas** (prevent resource exhaustion)
- **Version-controlled configurations**

## Troubleshooting

### Common Issues

#### Port Binding Errors
```bash
# Check if NET_BIND_SERVICE capability is applied
kubectl exec -n devops-challenge <pod-name> -- capsh --print
```

#### Permission Denied Errors
```bash
# Verify user context
kubectl exec -n devops-challenge <pod-name> -- id
kubectl exec -n devops-challenge <pod-name> -- whoami
```

#### Pod Not Starting
```bash
# Check pod events
kubectl describe pod <pod-name> -n devops-challenge

# Check logs
kubectl logs <pod-name> -n devops-challenge
```

### Debug Commands

```bash
# Check deployment status
kubectl get deployment secure-boot-app -n devops-challenge

# Check service status
kubectl get service secure-boot-app -n devops-challenge

# Check resource quotas
kubectl get resourcequota -n devops-challenge

# Port forward for testing
kubectl port-forward -n devops-challenge service/secure-boot-app 8080:80
```

## Testing and Validation

### Manual Testing
```bash
# Build and run locally
docker build -t secure-boot-app:test .
docker run --rm -p 8080:80 secure-boot-app:test
curl http://localhost:8080/
```

### Automated Testing
```bash
# Run full validation
./system-checks.sh

# Run specific checks
./system-checks.sh | grep "Check 1"  # User UID check
./system-checks.sh | grep "Check 2"  # Port binding check
./system-checks.sh | grep "Check 3"  # API response check
```

## Screenshots

### Setup Process
![Setup Script Execution](screenshots/setup-script.png)

### Kubernetes Resources
![Kubernetes Deployment](screenshots/k8s-resources.png)

### System Checks
![System Validation](screenshots/system-checks.png)

### API Response
![API Response](screenshots/api-response.png)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run the validation scripts
5. Submit a pull request

## License

This project is part of the DevOps Engineering Challenge and is provided for educational purposes.

---

**Note**: This solution demonstrates production-ready DevOps practices with a focus on security, automation, and reliability. The "Port 80 vs. Non-Root" challenge is solved using Linux capabilities, which provides the security benefits of non-root execution while meeting the application requirements.
