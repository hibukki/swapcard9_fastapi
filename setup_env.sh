#!/bin/bash

# Setup script for FastAPI Full Stack Project
# This script installs Docker and Docker Compose
#
# NOTE: This script requires a proper Linux environment with kernel support
# for Docker (networking modules, cgroups, etc.). It will not work in:
# - Nested containers without privileged mode
# - Environments without kernel module access
# - Some CI/CD runners without Docker-in-Docker (DinD)
#
# For those environments, Docker/Docker Compose must already be installed.

set -e

echo "=========================================="
echo "FastAPI Full Stack - Environment Setup"
echo "=========================================="

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "Running as root..."
else
    echo "Note: Some commands may require sudo privileges"
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
else
    echo "Cannot detect OS. Please install Docker manually."
    exit 1
fi

echo "Detected OS: $OS"

# Install Docker
echo ""
echo "Installing Docker..."
echo "--------------------"

if command -v docker &> /dev/null; then
    echo "Docker is already installed: $(docker --version)"
else
    case $OS in
        ubuntu|debian)
            # Update package index
            apt-get update

            # Install prerequisites
            apt-get install -y \
                ca-certificates \
                curl \
                gnupg \
                lsb-release

            # Add Docker's official GPG key
            install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/$OS/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            chmod a+r /etc/apt/keyrings/docker.gpg

            # Set up the repository
            echo \
              "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS \
              $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

            # Install Docker Engine
            apt-get update
            apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;

        centos|rhel|fedora)
            # Install required packages
            yum install -y yum-utils

            # Add Docker repository
            yum-config-manager --add-repo https://download.docker.com/linux/$OS/docker-ce.repo

            # Install Docker Engine
            yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

            # Start Docker
            systemctl start docker
            systemctl enable docker
            ;;

        *)
            echo "Unsupported OS: $OS"
            echo "Please install Docker manually from: https://docs.docker.com/engine/install/"
            exit 1
            ;;
    esac

    echo "Docker installed successfully: $(docker --version)"
fi

# Verify Docker Compose
echo ""
echo "Verifying Docker Compose..."
echo "---------------------------"
if docker compose version &> /dev/null; then
    echo "Docker Compose is available: $(docker compose version)"
else
    echo "Docker Compose plugin not found. It should be installed with Docker."
    exit 1
fi

# Start Docker service (if not running)
echo ""
echo "Starting Docker service..."
echo "-------------------------"
if systemctl is-active --quiet docker; then
    echo "Docker service is already running"
else
    if command -v systemctl &> /dev/null; then
        systemctl start docker
        echo "Docker service started"
    else
        echo "systemctl not found. Please start Docker manually."
    fi
fi

# Add current user to docker group (optional, requires re-login)
echo ""
echo "Docker Group Setup..."
echo "--------------------"
if [ "$EUID" -ne 0 ] && ! groups | grep -q docker; then
    echo "Note: To run Docker without sudo, add your user to the docker group:"
    echo "  sudo usermod -aG docker \$USER"
    echo "  Then log out and log back in."
fi

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Start the project:"
echo "   docker compose watch"
echo ""
echo "   Note: Use 'docker compose up' for non-development mode"
echo "   or 'docker compose up -d' to run in background"
echo ""
echo "2. Access the services:"
echo "   - Frontend: http://localhost:5173"
echo "   - Backend API: http://localhost:8000"
echo "   - API Docs: http://localhost:8000/docs"
echo "   - Adminer (DB): http://localhost:8080"
echo "   - Traefik UI: http://localhost:8090"
echo "   - MailCatcher: http://localhost:1080"
echo ""
echo "3. To stop the services:"
echo "   docker compose down"
echo ""
echo "4. To view logs:"
echo "   docker compose logs -f"
echo "   docker compose logs -f backend  # for specific service"
echo ""
echo "See development.md for more details."
echo ""
