#!/bin/sh
# setup.sh - Automatically configures the ZealLab APT repository on Debian/Ubuntu systems.
set -e

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root (using sudo)." >&2
    exit 1
fi

echo "=== Configuring ZealLab APT Repository ==="

# Create keyring directory
mkdir -m 0755 -p /etc/apt/keyrings

# Download signing key
echo "Downloading repository GPG key..."
if command -v curl >/dev/null 2>&1; then
    curl -fsSL https://zeallab-llc.github.io/Packages/zeallab-archive-keyring.asc -o /etc/apt/keyrings/zeallab-archive-keyring.asc
elif command -v wget >/dev/null 2>&1; then
    wget -qO /etc/apt/keyrings/zeallab-archive-keyring.asc https://zeallab-llc.github.io/Packages/zeallab-archive-keyring.asc
else
    echo "Error: Neither curl nor wget is installed. Please install one and run the script again." >&2
    exit 1
fi

# Detect Codename (default to trixie if unsupported or not Debian-based)
CODENAME="trixie"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ -n "${VERSION_CODENAME:-}" ]; then
        CODENAME="$VERSION_CODENAME"
    elif [ -n "${UBUNTU_CODENAME:-}" ]; then
        CODENAME="$UBUNTU_CODENAME"
    fi
fi

# Write sources list file using deb822 format
echo "Adding APT source entry for suite: ${CODENAME}..."
cat <<EOF > /etc/apt/sources.list.d/zeallab.sources
Types: deb
URIs: https://zeallab-llc.github.io/Packages/
Suites: ${CODENAME}
Components: main
Signed-By: /etc/apt/keyrings/zeallab-archive-keyring.asc
EOF

# Update package list
echo "Updating package index..."
apt-get update

echo "=== ZealLab Repository Configuration Complete! ==="
