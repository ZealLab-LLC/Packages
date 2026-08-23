#!/bin/bash
# fetch-agent.sh
# Downloads the prebuilt ZealLab Agent binary from the ZL_Agent repository's
# GitHub Release and stages it inside packages/zl-agent/ so dpkg-buildpackage
# can package it.
#
# The agent lives in its own repository and is built there; this repo only
# packages the resulting artifact.
#
# Usage: ./fetch-agent.sh <debian-arch>       e.g. ./fetch-agent.sh amd64
set -euo pipefail

readonly PKG_DIR="packages/zl-agent"
readonly AGENT_REPO="${ZL_AGENT_REPO:-ZealLab-LLC/ZL_Agent}"
readonly STAGE_DIR="${PKG_DIR}/usr/lib/zl-agent/bin"

DEB_ARCH="${1:-}"
if [[ -z "$DEB_ARCH" ]]; then
    echo "Usage: $0 <debian-arch>   (amd64|arm64)" >&2
    exit 2
fi

# Debian architecture -> the suffix used on the release asset.
case "$DEB_ARCH" in
    amd64) ASSET_ARCH="x64" ;;
    arm64) ASSET_ARCH="arm64" ;;
    *) echo "Error: unsupported architecture '$DEB_ARCH' (expected amd64 or arm64)" >&2; exit 2 ;;
esac

VERSION="$(tr -d '[:space:]' < "${PKG_DIR}/AGENT_VERSION")"
if [[ -z "$VERSION" ]]; then
    echo "Error: ${PKG_DIR}/AGENT_VERSION is empty." >&2
    exit 1
fi

# Guard against the pinned release and the changelog drifting apart, which would
# ship a binary whose version does not match the package version.
CHANGELOG_VERSION="$(dpkg-parsechangelog -l "${PKG_DIR}/debian/changelog" -S Version | sed 's/-[^-]*$//')"
if [[ "$CHANGELOG_VERSION" != "$VERSION" ]]; then
    echo "Error: version mismatch." >&2
    echo "  AGENT_VERSION:      ${VERSION}" >&2
    echo "  debian/changelog:   ${CHANGELOG_VERSION}" >&2
    echo "Bump both together." >&2
    exit 1
fi

readonly ASSET="zl-agent-linux-${ASSET_ARCH}.tar.gz"
readonly BASE_URL="https://github.com/${AGENT_REPO}/releases/download/v${VERSION}"

echo "Fetching ZealLab Agent ${VERSION} (${DEB_ARCH}/${ASSET_ARCH})..."

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# ZL_Agent is a public repository, so release assets download unauthenticated.
curl -fsSL -o "${TMP_DIR}/${ASSET}" "${BASE_URL}/${ASSET}"

# Verify against the checksum file published with the release.
if curl -fsSL -o "${TMP_DIR}/checksums.txt" "${BASE_URL}/checksums.txt"; then
    echo "Verifying checksum..."
    (cd "$TMP_DIR" && grep " ${ASSET}\$" checksums.txt | sha256sum -c -)
else
    echo "WARNING: no checksums.txt in the release; skipping verification." >&2
fi

tar -xzf "${TMP_DIR}/${ASSET}" -C "$TMP_DIR"

BINARY="$(find "$TMP_DIR" -type f -name 'zl-agent' -perm -u+x | head -n1)"
if [[ -z "$BINARY" ]]; then
    echo "Error: no 'zl-agent' executable inside ${ASSET}." >&2
    exit 1
fi

mkdir -p "$STAGE_DIR"
install -m 0755 "$BINARY" "${STAGE_DIR}/zl-agent"

echo "Staged ${STAGE_DIR}/zl-agent ($(du -h "${STAGE_DIR}/zl-agent" | cut -f1))"
