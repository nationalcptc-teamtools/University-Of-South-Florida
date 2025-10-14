
#!/usr/bin/env bash

# must be ran as sudo

echo "Setting up /opt directory..."
mkdir -p /opt/tools

# Get the actual user who ran sudo, not root
ACTUAL_USER=${SUDO_USER:-$USER}

chown -R "$ACTUAL_USER:$ACTUAL_USER" /opt
echo "Set ownership of /opt to $ACTUAL_USER"

# Install base dependencies and tools available via apt
apt-get update
APT_PACKAGES=(
    pipx
    nmap
    dnsrecon
    curl
    wget
    metasploit-framework
    john
    hydra
    hashcat
    git
    libssl-dev
    python3
    python3-pip
    python3-venv
    vim
    tmux
    flameshot
)

echo "Installing apt packages..."
DEBIAN_FRONTEND=noninteractive apt-get install -y "${APT_PACKAGES[@]}" || true

# Ask about seclists specifically
read -r -p "Do you want to install SecLists? This package is large (~4.7GB). [y/N]: " install_seclists
if [[ "${install_seclists,,}" =~ ^(y|yes)$ ]]; then
    echo "Installing SecLists..."
    DEBIAN_FRONTEND=noninteractive apt-get install -y seclists
fi

python3 -m pipx ensurepath
pipx ensurepath --global


PIPX_PACKAGES=(
    "updog"
)

for pkg in "${PIPX_PACKAGES[@]}"; do
    if ! command -v "${pkg%%-*}" >/dev/null 2>&1; then
        echo "Installing $pkg via pipx..."
        pipx install "$pkg" --system-site-packages || true
    fi
done


cp "./tools/ultimate-nmap-parser.sh" /usr/local/bin/ultimate-nmap-parser
chmod +x /usr/local/bin/ultimate-nmap-parser

# Install docker 
curl -fsSL https://get.docker.com | sh

# Install Go - thx gerb
echo "Goooooolang setup"
go=$(curl https://go.dev/dl/ -s 2>/dev/null | grep linux | grep $(dpkg --print-architecture) | head -n 1 | grep -oP '(?<=href=")[^"]*')
wget https://go.dev$go
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf $(echo $go | awk -F "/" '{print $3}')
rm -rf $(echo $go | awk -F "/" '{print $3}')
mkdir -p ~/go

echo -e 'export PATH=~/.local/bin:$PATH\nexport PATH=$PATH:/usr/local/go/bin\nexport GOPATH=$HOME/go\nexport PATH=$PATH:$GOPATH/bin\n' >> ~/.zshrc
source ~/.zshrc

echo "All set :)"