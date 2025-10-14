#!/usr/bin/env bash

set -euo pipefail

# ========== DEBUG SECTION START ==========
# Remove this entire section for production
debug_confirm() {
    local action="$1"
    echo -e "\e[1;33m[DEBUG] About to: $action\e[0m"
    read -r -p "Continue? [y/N]: " response
    if [[ ! "${response,,}" =~ ^(y|yes)$ ]]; then
        echo "Skipping..."
        return 1
    fi
    return 0
}
# ========== DEBUG SECTION END ============

# Function to install Go binaries
install_go_binary() {
    local pkg="$1"
    local bin="${2:-$(basename "$pkg")}"
    if ! command -v "$bin" >/dev/null 2>&1; then
        echo "Installing $bin via Go..."
        if ! command -v go >/dev/null 2>&1; then
            apt-get install -y golang-go
        fi
        GOBIN=/usr/local/bin go install "${pkg}@latest" || true
    fi
}

echo "Installing Active Directory tools..."

# Get script directory for copying tools
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the actual user who ran sudo, not root
ACTUAL_USER=${SUDO_USER:-$USER}
if [ "$ACTUAL_USER" = "root" ]; then
    echo "Error: Please run this script with sudo, not as root directly"
    exit 1
fi

# Install base dependencies and tools available via apt
apt-get update
APT_PACKAGES=(
    python3
    python3-pip
    smbclient
    wget
    git
    proxychains4
    python3-impacket
    evil-winrm
    responder
    krbrelayx
)

if debug_confirm "Install APT packages: ${APT_PACKAGES[*]}"; then
    echo "Installing apt packages..."
    DEBIAN_FRONTEND=noninteractive apt-get install -y "${APT_PACKAGES[@]}" || true
fi

# Ensure pipx is available and in PATH
if ! command -v pipx >/dev/null 2>&1; then
    python3 -m pip install --user pipx
    python3 -m pipx ensurepath
fi

# Install Python packages via pipx
PIPX_PACKAGES=(
    "impacket"
    "mitm6"
    "certipy-ad"
    "coercer"
    "bloodyAD"
    "netexec"
)

for pkg in "${PIPX_PACKAGES[@]}"; do
    if ! command -v "${pkg%%-*}" >/dev/null 2>&1; then
        if debug_confirm "Install $pkg via pipx"; then
            echo "Installing $pkg via pipx..."
            pipx install "$pkg" --system-site-packages || true
        fi
    fi
done

# Create necessary directories
echo "Creating directories in /opt..."
mkdir -p /opt/{ad-tools,ligolo-ng}

# Install ligolo-ng
if debug_confirm "Install ligolo-ng"; then
    echo "Installing ligolo-ng..."
    if [ -d "$SCRIPT_DIR/ligolo-ng" ]; then
        # Copy ligolo-ng files
        cp -r "$SCRIPT_DIR/ligolo-ng/"* /opt/ligolo-ng/
        
        # Create symbolic links for Linux binaries if they exist
        if [ -f "/opt/ligolo-ng/linux/agent" ] && [ -f "/opt/ligolo-ng/linux/proxy" ]; then
            chmod +x /opt/ligolo-ng/linux/{agent,proxy}
            ln -sf /opt/ligolo-ng/linux/agent /usr/local/bin/ligolo-agent
            ln -sf /opt/ligolo-ng/linux/proxy /usr/local/bin/ligolo-proxy
        else
            echo "Warning: ligolo-ng binaries not found in the tools directory"
        fi
    else
        echo "Warning: ligolo-ng directory not found in $SCRIPT_DIR"
    fi
fi

# Copy AD Tools
if debug_confirm "Install AD tools and scripts"; then
    echo "Installing AD tools..."
    if [ -d "$SCRIPT_DIR/ad-tools" ]; then
        # Copy AD tools
        cp -r "$SCRIPT_DIR/ad-tools/"* /opt/ad-tools/
        
        # Verify PowerShell scripts
        if [ -d "/opt/ad-tools/powershell" ]; then
            echo "PowerShell scripts installed"
        else
            echo "Warning: PowerShell scripts not found in tools directory"
        fi
        
        # Verify Windows binaries
        if [ -d "/opt/ad-tools/binaries" ]; then
            echo "Windows binaries installed"
        else
            echo "Warning: Windows binaries not found in tools directory"
        fi
    else
        echo "Warning: ad-tools directory not found in $SCRIPT_DIR"
    fi
fi

# Install Go-based tools
if debug_confirm "Install Kerbrute"; then
    echo "Installing Kerbrute..."
    install_go_binary "github.com/ropnop/kerbrute" "kerbrute"
fi

if debug_confirm "Install Chisel"; then
    echo "Installing Chisel..."
    install_go_binary "github.com/jpillora/chisel" "chisel"
fi

# Set proper ownership
chown -R "$ACTUAL_USER:$ACTUAL_USER" /opt/{ad-tools,ligolo-ng}
echo "Set ownership of /opt directories to $ACTUAL_USER"

echo "AD tools installation complete"