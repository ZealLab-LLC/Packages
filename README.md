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
curl -fsSL https://zeallab-llc.github.io/Packages/setup.sh | sudo sh && sudo apt-get install -y zl-tools zl-theme
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
   sudo apt-get install -y zl-tools zl-theme
   ```


## License

All software within this repository is distributed under the GNU General Public License version 3 (GPLv3). Refer to the `LICENSE` file for details.
