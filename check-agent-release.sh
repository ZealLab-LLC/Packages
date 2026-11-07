#!/usr/bin/env bash
set -euo pipefail

readonly AGENT_REPO="${ZL_AGENT_REPO:-ZealLab-LLC/ZL_Agent}"
readonly APT_URL="https://zeallab-llc.github.io/Packages"
pinned=$(tr -d '[:space:]' < packages/zl-agent/AGENT_VERSION)

if [[ "$pinned" == latest ]]; then
    release_url="https://api.github.com/repos/$AGENT_REPO/releases/latest"
elif [[ -n "$pinned" ]]; then
    release_url="https://api.github.com/repos/$AGENT_REPO/releases/tags/v$pinned"
else
    echo "AGENT_VERSION is empty." >&2
    exit 1
fi

release=$(curl -fsSL --retry 3 "$release_url")
tag=$(jq -er '.tag_name' <<< "$release")
version="${tag#v}"
dpkg --validate-version "$version-1"
if [[ "$pinned" != latest && "$version" != "$pinned" ]]; then
    echo "Release $tag does not match the configured version $pinned." >&2
    exit 1
fi

# A published release must supply everything the two architecture builds consume.
jq -e '
    [.assets[].name] as $assets |
    ["zl-agent-linux-x64.tar.gz", "zl-agent-linux-arm64.tar.gz", "checksums.txt"] |
    all(.[]; . as $name | $assets | index($name) != null)
' <<< "$release" >/dev/null

publish=true
if [[ "$GITHUB_EVENT_NAME" == schedule ]]; then
    publish=false
    for arch in amd64 arm64; do
        current=$(curl -fsSL --retry 3 "$APT_URL/dists/trixie/main/binary-$arch/Packages" | awk '
            BEGIN { RS = ""; FS = "\n" }
            /(^|\n)Package: zl-agent(\n|$)/ {
                for (i = 1; i <= NF; i++) {
                    if ($i ~ /^Version: /) {
                        sub(/^Version: /, "", $i)
                        print $i
                        exit
                    }
                }
            }
        ')
        if [[ -z "$current" ]] || dpkg --compare-versions "$current" lt "$version-1"; then
            publish=true
            break
        fi
    done
fi

printf 'version=%s\npublish=%s\n' "$version" "$publish" >> "$GITHUB_OUTPUT"
echo "Agent $version selected; publish=$publish"
