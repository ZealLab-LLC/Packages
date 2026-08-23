# ZealLab LLC Package Repository

This repository hosts official Debian packages for ZealLab systems. The package index is published as an APT repository hosted on GitHub Pages and signed with GPG.

## Packages

### `zl-tools`
Command-line utility suite for ZealLabOS systems.
- **Architecture**: `all`
- **Dependencies**: `bash`, `wl-clipboard | xclip | xsel`
- **Command Dispatcher**: `/usr/bin/zl`
- **Utility Library**: `/usr/lib/zl/`
- **Included Utilities**:
  - `copy`: Copies input (pipe, file, or string) to system clipboard.
  - `paste`: Outputs system clipboard contents to stdout.
  - `update`: Updates package index and upgrades all system packages.
  - `log`: Filters current boot system journal logs for graphics, audio, and session warnings/errors.
  - `agent` (`zl agent`): ZealLab Agent (fork of OpenCode), a local-only development agent (works only if `zl-agent` is installed).

### `zl-agent`
ZealLab Agent — a local-only AI development agent (fork of OpenCode) for ZealLabOS, invoked as `zl agent` (works only if `zl-agent` is installed).
- **Architecture**: `amd64`, `arm64`
- **Dependencies**: `zl-tools`
- **Subcommand**: `/usr/lib/zl/agent`
- **Binary**: `/usr/lib/zl-agent/bin/zl-agent`
- **Requires**: [Ollama](https://ollama.com) installed and running. This package
  does not install or manage it.
- **Source**: built and released from
  [ZealLab-LLC/ZL_Agent](https://github.com/ZealLab-LLC/ZL_Agent); this repo only
  packages the released binary.

The agent runs entirely against a local Ollama daemon — no cloud account, no API
key, and no outbound network access during normal use.

```bash
zl agent                 # start the TUI in the current project
zl agent run "..."       # one-shot, non-interactive
zl agent models          # list local models
```

### `zl-theme`
Custom SDDM theme (zeal-blade) and lock screen theme for ZealLabOS.
- **Architecture**: `all`
- **Dependencies**: `sddm`
- **Installation Paths**:
  - `/usr/share/sddm/themes/zeal-blade/`
  - `/usr/share/zeallab/lockscreen/`
  - `/usr/share/zeallab/assets/`

---

## Quick Setup

To configure the repository and install the packages automatically on Debian/Ubuntu systems, run the following one-liner:

```bash
curl -fsSL https://zeallab-llc.github.io/Packages/setup.sh | sudo sh && sudo apt-get install -y zl-tools zl-theme zl-agent
```

---

## Manual Configuration (Debian 13 / Trixie)

Follow the steps below to add this repository manually:

1. **Download the GPG repository signing key**:
   ```bash
   sudo mkdir -p /etc/apt/keyrings
   sudo wget -O /etc/apt/keyrings/zeallab-archive-keyring.asc https://zeallab-llc.github.io/Packages/zeallab-archive-keyring.asc
   ```

2. **Add the repository source description file**:
   ```bash
   cat <<EOF | sudo tee /etc/apt/sources.list.d/zeallab.sources
   Types: deb
   URIs: https://zeallab-llc.github.io/Packages/
   Suites: trixie
   Components: main
   Signed-By: /etc/apt/keyrings/zeallab-archive-keyring.asc
   EOF
   ```

3. **Update the package lists and install the package**:
   ```bash
   sudo apt-get update
   sudo apt-get install -y zl-tools zl-theme zl-agent
   ```


---

## Building

`./build-repo.sh` builds every package and assembles the signed APT tree into
`public/`.

`zl-agent` is handled specially: its binary is **not** stored in this repo.
`fetch-agent.sh` downloads the release asset pinned by
`packages/zl-agent/AGENT_VERSION` from the ZL_Agent repository, verifies its
SHA-256 against the release's `checksums.txt`, and stages it before packaging.
The package is then built once per architecture.

```bash
./build-repo.sh              # full build (needs network for the agent)
SKIP_AGENT=1 ./build-repo.sh # skip zl-agent, build the rest offline
```

### Releasing a new agent version

1. Tag [ZL_Agent](https://github.com/ZealLab-LLC/ZL_Agent) (`git tag v1.0.1 && git push origin v1.0.1`);
   its workflow publishes the Linux binaries.
2. Here, bump `packages/zl-agent/AGENT_VERSION` **and**
   `packages/zl-agent/debian/changelog` to the same version, then push.

The build fails if those two disagree, so a mismatched package cannot ship.

## License

All software within this repository is distributed under the GNU General Public License version 3 (GPLv3). Refer to the `LICENSE` file for details.
