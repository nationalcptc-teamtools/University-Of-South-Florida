#!/usr/bin/env bash

set -euo pipefail


APT_PACKAGES=(
    gobuster
    sqlmap
    whatweb
    sslscan
    ffuf
    dirsearch
    burpsuite
    feroxbuster
)

echo "Installing apt packages..."
DEBIAN_FRONTEND=noninteractive apt-get install -y "${APT_PACKAGES[@]}" || true

# Ensure pipx is available
if ! command -v pipx >/dev/null 2>&1; then
    python3 -m pip install --user pipx
    python3 -m pipx ensurepath
fi

# Install tools via pipx if not available through apt
PIPX_PACKAGES=(
)

for pkg in "${PIPX_PACKAGES[@]}"; do
    if ! command -v "${pkg%%-*}" >/dev/null 2>&1; then
        echo "Installing $pkg via pipx..."
        pipx install "$pkg" || true
    fi
done


if ! command -v linpeas >/dev/null 2>&1; then
    if [ ! -d "/opt/linpeas" ]; then
        echo "Installing linPEAS..."
        mkdir -p /opt/linpeas
        wget -q -O /opt/linpeas/linpeas.sh \
            "https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh"
        chmod +x /opt/linpeas/linpeas.sh
        ln -sf /opt/linpeas/linpeas.sh /usr/local/bin/linpeas
    fi
fi


# go tools
go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
CGO_ENABLED=1 go install github.com/projectdiscovery/katana/cmd/katana@latest
go install github.com/hakluke/hakrawler@latest

# install aquatone
wget 'https://github.com/michenriksen/aquatone/releases/download/v1.7.0/aquatone_linux_amd64_1.7.0.zip'
unzip aquatone_linux_amd64_1.7.0.zip
mv aquatone/aquatone /usr/bin/aquatone
rm -rf ./aquatone

# https://commondatastorage.googleapis.com/chromium-browser-snapshots/Linux_x64/1529300/chrome-linux.zip
go install github.com/sensepost/gowitness@latest