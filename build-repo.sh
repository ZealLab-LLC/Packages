#!/bin/bash
# build-repo.sh
# Automates building Debian packages and structuring the APT repository for GitHub Pages.
set -euo pipefail

CODENAME="trixie" # Debian 13
REPO_DIR="public"

# Architectures the repository advertises. Most packages are "all"; zl-agent
# ships a compiled binary and so is built per-architecture.
ARCHES="amd64 i386 arm64 armhf"
AGENT_ARCHES="amd64 arm64"

# zl-agent pulls a prebuilt binary from the ZL_Agent repository's releases.
# Set SKIP_AGENT=1 to build the rest of the repo without network access.
SKIP_AGENT="${SKIP_AGENT:-0}"

echo "=== Starting APT Repository Build ==="

# Clean any previous builds
echo "Cleaning up old build artifacts..."
rm -rf "${REPO_DIR}"
rm -f packages/*.deb packages/*.changes packages/*.buildinfo

# Create output directories
echo "Creating repository directory structure..."
mkdir -p "${REPO_DIR}/dists/${CODENAME}/main/binary-all"
for arch in ${ARCHES}; do
    mkdir -p "${REPO_DIR}/dists/${CODENAME}/main/binary-${arch}"
done
mkdir -p "${REPO_DIR}/pool/main"

# Build the architecture-independent packages.
echo "Building packages..."
for pkg_dir in packages/*; do
    if [ -d "$pkg_dir" ] && [ -d "$pkg_dir/debian" ]; then
        # zl-agent is architecture-specific and handled separately below.
        if [ "$(basename "$pkg_dir")" = "zl-agent" ]; then
            continue
        fi
        echo "Building $(basename "$pkg_dir")..."
        cd "$pkg_dir"
        dpkg-buildpackage -us -uc -b -d
        cd ../..
    fi
done

# Build zl-agent once per architecture, staging the matching prebuilt binary
# before each run. Nothing is compiled here, so cross-building with -a is safe.
if [ "$SKIP_AGENT" = "1" ]; then
    echo "SKIP_AGENT=1 - skipping the zl-agent package."
elif [ -d packages/zl-agent/debian ]; then
    for arch in ${AGENT_ARCHES}; do
        echo "Building zl-agent (${arch})..."
        ./fetch-agent.sh "${arch}"
        (cd packages/zl-agent && dpkg-buildpackage -us -uc -b -d -a "${arch}")
        rm -f packages/zl-agent/usr/lib/zl-agent/bin/zl-agent
    done
fi


# Move built packages to pool
echo "Moving built packages to repository pool..."
mv packages/*.deb "${REPO_DIR}/pool/main/"

# Clean up build artifacts outside of pool
rm -f packages/*.changes packages/*.buildinfo

# Generate Packages file
echo "Generating Packages files..."
cd "${REPO_DIR}"
# Each index lists the "all" packages plus the ones built for that
# architecture, so apt never offers an amd64 binary to an arm64 machine.
# apt-ftparchive has no architecture filter for the "packages" command, so the
# combined output is scanned once and split by the Architecture field.
echo "Splitting indexes by architecture..."
apt-ftparchive packages pool/main > /tmp/zl-packages-all

split_index() {
    # $1 = architecture to select, $2 = destination Packages file
    awk -v want="$1" '
        BEGIN { RS = ""; ORS = "\n\n" }
        {
            arch = ""
            n = split($0, line, "\n")
            for (i = 1; i <= n; i++) {
                if (line[i] ~ /^Architecture: /) {
                    arch = substr(line[i], 15)
                    break
                }
            }
            if (arch == want || arch == "all") print
        }
    ' /tmp/zl-packages-all > "$2"
}

split_index all "dists/${CODENAME}/main/binary-all/Packages"
gzip -k -f -9 "dists/${CODENAME}/main/binary-all/Packages"

for arch in ${ARCHES}; do
    split_index "${arch}" "dists/${CODENAME}/main/binary-${arch}/Packages"
    gzip -k -f -9 "dists/${CODENAME}/main/binary-${arch}/Packages"
done

rm -f /tmp/zl-packages-all

# Generate Release file
echo "Generating Release file..."
apt-ftparchive \
  -o APT::FTPArchive::Release::Origin="ZealLab" \
  -o APT::FTPArchive::Release::Label="ZealLab" \
  -o APT::FTPArchive::Release::Suite="stable" \
  -o APT::FTPArchive::Release::Codename="${CODENAME}" \
  -o APT::FTPArchive::Release::Architectures="all ${ARCHES}" \
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
    gpg --batch --yes --pinentry-mode loopback --passphrase "" --default-key "${KEY_ID}" --clearsign --output dists/${CODENAME}/InRelease dists/${CODENAME}/Release
    gpg --batch --yes --pinentry-mode loopback --passphrase "" --default-key "${KEY_ID}" --detach-sign --armor --output dists/${CODENAME}/Release.gpg dists/${CODENAME}/Release
else
    echo "WARNING: GPG_PRIVATE_KEY is not set. Release files will not be signed."
fi

# Copy helper setup script to repository root
echo "Copying repository setup script..."
cp ../setup.sh .

echo "=== APT Repository Build Complete! ==="

