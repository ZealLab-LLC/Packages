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

# AGENT_VERSION is either an explicit pin ("1.0.7") or the word "latest", in
# which case the newest published release is resolved from the GitHub API.
PINNED="$(tr -d '[:space:]' < "${PKG_DIR}/AGENT_VERSION")"
if [[ -z "$PINNED" ]]; then
    echo "Error: ${PKG_DIR}/AGENT_VERSION is empty (expected a version or 'latest')." >&2
    exit 1
fi

if [[ "$PINNED" == "latest" ]]; then
    # CI resolves latest once so both architecture builds use the same release.
    VERSION="${ZL_AGENT_VERSION:-}"
    if [[ -z "$VERSION" ]]; then
        VERSION="$(curl -fsSL "https://api.github.com/repos/${AGENT_REPO}/releases/latest" \
            | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"v\{0,1\}\([^"]*\)".*/\1/p' | head -n1)"
    fi
    if [[ -z "$VERSION" ]]; then
        echo "Error: could not resolve the latest ${AGENT_REPO} release." >&2
        exit 1
    fi
    echo "Resolved latest release: ${VERSION}"
else
    VERSION="$PINNED"
    # A pin must agree with the changelog, or the package would claim a version
    # its binary does not match. When tracking latest, build-repo.sh stamps the
    # changelog instead, so there is nothing to drift.
    CHANGELOG_VERSION="$(dpkg-parsechangelog -l "${PKG_DIR}/debian/changelog" -S Version | sed 's/-[^-]*$//')"
    if [[ "$CHANGELOG_VERSION" != "$VERSION" ]]; then
        echo "Error: version mismatch." >&2
        echo "  AGENT_VERSION:      ${VERSION}" >&2
        echo "  debian/changelog:   ${CHANGELOG_VERSION}" >&2
        echo "Bump both together, or set AGENT_VERSION to 'latest'." >&2
        exit 1
    fi
fi

# Hand the resolved version to build-repo.sh, which stamps debian/changelog.
printf '%s\n' "$VERSION" > "${PKG_DIR}/.resolved-version"

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
