#!/usr/bin/env bash

set -euo pipefail

# Function to check if script is run as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "This script must be run as root"
        exit 1
    fi
}

# Function to install Docker and Docker Compose
install_docker() {
    echo "Installing Docker and Docker Compose..."
    
    # Install docker.io and docker-compose packages
    apt-get update
    apt-get install -y docker.io docker-compose

    # Add user to docker group
    if [ -n "${SUDO_USER:-}" ]; then
        usermod -aG docker "$SUDO_USER"
        echo "Added $SUDO_USER to docker group"
    fi

    # Start and enable Docker service
    systemctl start docker
    systemctl enable docker
    
    # Verify Docker is running
    if ! systemctl is-active --quiet docker; then
        echo "Error: Docker service failed to start"
        exit 1
    fi
    
    # Verify docker-compose is installed
    if ! command -v docker-compose &> /dev/null; then
        echo "Error: docker-compose installation failed"
        exit 1
    fi

    echo "Docker and Docker Compose installation completed"
}

# Function to install BloodHound CLI
install_bloodhound_cli() {
    echo "Installing BloodHound CLI..."
    
    # Get the actual user who ran sudo
    ACTUAL_USER=${SUDO_USER:-$USER}
    if [ "$ACTUAL_USER" = "root" ]; then
        echo "Error: Please run this script with sudo, not as root directly"
        exit 1
    fi
    
    # Create bloodhound-cli directory in /opt
    mkdir -p /opt/bloodhound-cli
    cd /opt/bloodhound-cli
    
    # Download and extract bloodhound-cli
    wget https://github.com/SpecterOps/bloodhound-cli/releases/latest/download/bloodhound-cli-linux-amd64.tar.gz
    tar -xvzf bloodhound-cli-linux-amd64.tar.gz
    
    # Cleanup downloaded archive
    rm bloodhound-cli-linux-amd64.tar.gz
    
    # Make binary executable
    chmod +x bloodhound-cli
    
    # Create symbolic link
    ln -sf /opt/bloodhound-cli/bloodhound-cli /usr/local/bin/bloodhound-cli
    
    # Set proper ownership
    chown -R "$ACTUAL_USER:$ACTUAL_USER" /opt/bloodhound-cli
    echo "Set ownership of /opt/bloodhound-cli to $ACTUAL_USER"
    
    # Run bloodhound-cli install as the actual user
    echo "Running bloodhound-cli install as $ACTUAL_USER..."
    su - "$ACTUAL_USER" -c "/opt/bloodhound-cli/bloodhound-cli install"
    
    echo "BloodHound CLI installation completed"
}

# Main execution
main() {
    check_root
    install_docker
    install_bloodhound_cli
}

main
