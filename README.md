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
