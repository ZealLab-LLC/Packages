#!/bin/bash
# build-repo.sh
# Automates building Debian packages and structuring the APT repository for GitHub Pages.
set -euo pipefail

CODENAME="trixie" # Debian 13
REPO_DIR="public"

echo "=== Starting APT Repository Build ==="

# Clean any previous builds
echo "Cleaning up old build artifacts..."
rm -rf "${REPO_DIR}"
rm -f packages/*.deb packages/*.changes packages/*.buildinfo

# Create output directories
echo "Creating repository directory structure..."
mkdir -p "${REPO_DIR}/dists/${CODENAME}/main/binary-all"
mkdir -p "${REPO_DIR}/dists/${CODENAME}/main/binary-amd64"
mkdir -p "${REPO_DIR}/pool/main"

# Build all packages in packages/
echo "Building packages..."
cd packages/zl
dpkg-buildpackage -us -uc -b -d
cd ../..


# Move built packages to pool
echo "Moving built packages to repository pool..."
mv packages/*.deb "${REPO_DIR}/pool/main/"

# Clean up build artifacts outside of pool
rm -f packages/*.changes packages/*.buildinfo

# Generate Packages file
echo "Generating Packages files..."
cd "${REPO_DIR}"
apt-ftparchive packages pool/main > dists/${CODENAME}/main/binary-all/Packages
gzip -k -f -9 dists/${CODENAME}/main/binary-all/Packages

# Duplicate for binary-amd64 compatibility
cp dists/${CODENAME}/main/binary-all/Packages dists/${CODENAME}/main/binary-amd64/Packages
gzip -k -f -9 dists/${CODENAME}/main/binary-amd64/Packages

# Generate Release file
echo "Generating Release file..."
apt-ftparchive \
  -o APT::FTPArchive::Release::Origin="ZealLab" \
  -o APT::FTPArchive::Release::Label="ZealLab" \
  -o APT::FTPArchive::Release::Suite="stable" \
  -o APT::FTPArchive::Release::Codename="${CODENAME}" \
  -o APT::FTPArchive::Release::Architectures="all amd64" \
  -o APT::FTPArchive::Release::Components="main" \
  -o APT::FTPArchive::Release::Description="ZealLab OS Packages Repository" \
  release dists/${CODENAME} > dists/${CODENAME}/Release

# Sign Release file if GPG key is present
if [ -n "${GPG_PRIVATE_KEY:-}" ]; then
    echo "Importing GPG private key..."
    echo "$GPG_PRIVATE_KEY" | gpg --batch --import
    
    # Get imported GPG Key ID
    KEY_ID=$(gpg --list-secret-keys --keyid-format LONG | grep sec | awk '{print $2}' | cut -d'/' -f2 | head -n1)
    echo "Using GPG Key ID: ${KEY_ID}"
    
    # Export public key for users to download
    # ASCII-armored format
    gpg --armor --export "${KEY_ID}" > zeallab-archive-keyring.asc
    # Binary format
    gpg --export "${KEY_ID}" > zeallab-archive-keyring.gpg
    
    # Sign Release
    echo "Signing Release..."
    gpg --batch --yes --default-key "${KEY_ID}" --clearsign --output dists/${CODENAME}/InRelease dists/${CODENAME}/Release
    gpg --batch --yes --default-key "${KEY_ID}" --detach-sign --armor --output dists/${CODENAME}/Release.gpg dists/${CODENAME}/Release
else
    echo "WARNING: GPG_PRIVATE_KEY is not set. Release files will not be signed."
fi

echo "=== APT Repository Build Complete! ==="
