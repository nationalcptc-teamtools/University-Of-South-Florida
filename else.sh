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
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y "${APT_PACKAGES[@]}" || true


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
go install github.com/sensepost/gowitness@latest