#!/bin/bash
# fetch-autodev.sh
# Downloads the prebuilt ZealLab AutoDev binary and stages it inside
# packages/zl-autodev/ so dpkg-buildpackage can package it.
#
# AutoDev is developed in a private repository. Its release workflow publishes
# the binaries as releases of THIS public repository (tags zl-autodev-v<version>),
# so they download without credentials and nothing that can read the private
# repository is stored here.
#
# Usage: ./fetch-autodev.sh <debian-arch>       e.g. ./fetch-autodev.sh amd64
set -euo pipefail

readonly PKG_DIR="packages/zl-autodev"
readonly RELEASE_REPO="${ZL_AUTODEV_RELEASE_REPO:-ZealLab-LLC/Packages}"
readonly STAGE_DIR="${PKG_DIR}/usr/lib/zl-autodev/bin"

DEB_ARCH="${1:-}"
case "$DEB_ARCH" in
    amd64) ASSET_ARCH="x64" ;;
    arm64) ASSET_ARCH="arm64" ;;
    *) echo "Usage: $0 <debian-arch>   (amd64|arm64)" >&2; exit 2 ;;
esac

# AUTODEV_VERSION is an explicit pin ("0.1.0") or "latest": the highest
# zl-autodev-v* release of RELEASE_REPO. ZL_AUTODEV_VERSION (from a release
# dispatch, or set by build-repo.sh after the first architecture) wins.
PINNED="$(tr -d '[:space:]' < "${PKG_DIR}/AUTODEV_VERSION")"
VERSION="${ZL_AUTODEV_VERSION:-}"
if [[ -n "$VERSION" && "$PINNED" != "latest" && "$VERSION" != "$PINNED" ]]; then
    echo "Error: requested AutoDev ${VERSION} conflicts with the pin ${PINNED}." >&2
    exit 1
fi
if [[ -z "$VERSION" && "$PINNED" != "latest" ]]; then
    VERSION="$PINNED"
fi
if [[ -z "$VERSION" ]]; then
    auth=()
    [[ -n "${GITHUB_TOKEN:-}" ]] && auth=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
    VERSION="$(curl -fsSL "${auth[@]}" "https://api.github.com/repos/${RELEASE_REPO}/releases?per_page=100" \
        | jq -r '[.[] | select(.draft | not) | .tag_name | select(startswith("zl-autodev-v")) | ltrimstr("zl-autodev-v")
                  | select(test("^[0-9]+\\.[0-9]+\\.[0-9]+$"))]
                 | sort_by(split(".") | map(tonumber)) | last // empty')"
    if [[ -z "$VERSION" ]]; then
        echo "Error: no zl-autodev-v* release found on ${RELEASE_REPO}." >&2
        exit 1
    fi
    echo "Resolved latest AutoDev release: ${VERSION}"
fi

# Hand the resolved version to build-repo.sh, which stamps debian/changelog.
printf '%s\n' "$VERSION" > "${PKG_DIR}/.resolved-version"

readonly ASSET="zl-autodev-linux-${ASSET_ARCH}.tar.gz"
readonly BASE_URL="https://github.com/${RELEASE_REPO}/releases/download/zl-autodev-v${VERSION}"

echo "Fetching ZealLab AutoDev ${VERSION} (${DEB_ARCH}/${ASSET_ARCH})..."
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

curl -fsSL -o "${TMP_DIR}/${ASSET}" "${BASE_URL}/${ASSET}"
curl -fsSL -o "${TMP_DIR}/checksums.txt" "${BASE_URL}/checksums.txt"
echo "Verifying checksum..."
(cd "$TMP_DIR" && grep " ${ASSET}\$" checksums.txt | sha256sum -c -)

tar -xzf "${TMP_DIR}/${ASSET}" -C "$TMP_DIR"
if [[ ! -x "${TMP_DIR}/zl-autodev" ]]; then
    echo "Error: no 'zl-autodev' executable inside ${ASSET}." >&2
    exit 1
fi

mkdir -p "$STAGE_DIR"
install -m 0755 "${TMP_DIR}/zl-autodev" "${STAGE_DIR}/zl-autodev"
echo "Staged ${STAGE_DIR}/zl-autodev ($(du -h "${STAGE_DIR}/zl-autodev" | cut -f1))"
