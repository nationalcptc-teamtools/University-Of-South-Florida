#!/usr/bin/zsh

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "must be ran as sudo"
  exit 1
fi

echo "Setting up /opt directory..."
mkdir -p /opt/tools

# Get the actual user who ran sudo, not root
ACTUAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6 || echo "/home/$ACTUAL_USER")

chown -R "$ACTUAL_USER:$ACTUAL_USER" /opt
echo "Set ownership of /opt to $ACTUAL_USER"

# Install base dependencies and tools available via apt
export DEBIAN_FRONTEND=noninteractive
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

apt-get install -y --no-install-recommends "${APT_PACKAGES[@]}" || true

# Ask about seclists specifically
read -r "install_seclists?Do you want to install SecLists? This package is large (~4.7GB). [y/N]: "
if [[ "${(L)install_seclists}" =~ ^(y|yes)$ ]]; then
    apt-get install -y --no-install-recommends seclists || true
fi

python3 -m pipx ensurepath || true
pipx ensurepath --global || true

PIPX_PACKAGES=(
    "updog"
)

for pkg in "${PIPX_PACKAGES[@]}"; do
    if ! command -v "${pkg%%-*}" >/dev/null 2>&1; then
        echo "Installing $pkg via pipx..."
        pipx install "$pkg" --system-site-packages || true
    fi
done

if [[ -f "./tools/ultimate-nmap-parser.sh" ]]; then
    cp "./tools/ultimate-nmap-parser.sh" /usr/local/bin/ultimate-nmap-parser
    chmod +x /usr/local/bin/ultimate-nmap-parser
fi

# Install docker
mkdir -p /etc/apt/keyrings
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" > /etc/apt/sources.list.d/docker.list
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io || true

# Install Go - thx gerb
echo "Goooooolang setup"
go_page=$(curl -s https://go.dev/dl/ | grep linux | grep "$(dpkg --print-architecture)" | head -n 1 || true)
if [[ -n "$go_page" ]]; then
    go_href=$(echo "$go_page" | grep -oP '(?<=href=")[^"]*' || true)
    if [[ -n "$go_href" ]]; then
        tmpfile="/tmp/$(basename "$go_href")"
        wget -q "https://go.dev${go_href}" -O "$tmpfile" || true
        rm -rf /usr/local/go
        mkdir -p /usr/local
        if [[ -f "$tmpfile" ]]; then
            tar -C /usr/local -xzf "$tmpfile" || true
            rm -f "$tmpfile"
        fi
    fi
fi
mkdir -p "${USER_HOME}/go"

chown -R "$ACTUAL_USER:$ACTUAL_USER" "${USER_HOME}/go"

# preserve original zshrc PATH additions
ZSHRC="${USER_HOME}/.zshrc"
grep -Fq 'export PATH=~/.local/bin:$PATH' "$ZSHRC" 2>/dev/null || {
  cat >> "$ZSHRC" <<'EOF'
export PATH=~/.local/bin:$PATH
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
EOF
  chown "$ACTUAL_USER:$ACTUAL_USER" "$ZSHRC" || true
}

if [[ -x "./fixtmux.sh" ]]; then
    sudo -u "$ACTUAL_USER" bash ./fixtmux.sh || true
fi

# source zshrc if possible for this session
if [[ -f "$ZSHRC" ]]; then
    # shellcheck disable=SC1090
    source "$ZSHRC" || true
fi

echo "All set :)"
