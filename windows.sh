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
    smbclient
    python3-impacket
    evil-winrm
    responder
    krbrelayx
    certipy-ad
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
    "mitm6"
    "certipy-ad" # cant find
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


# Install Go-based tools
if debug_confirm "Install Kerbrute"; then
    echo "Installing Kerbrute..."
    install_go_binary "github.com/ropnop/kerbrute" "kerbrute"
fi

if debug_confirm "Install Chisel"; then
    echo "Installing Chisel..."
    install_go_binary "github.com/jpillora/chisel" "chisel"
fi

echo "AD tools installation complete"