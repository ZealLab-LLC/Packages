# ZealLab LLC Package Repository

This repository hosts official Debian packages for ZealLab systems. The package index is published as an APT repository hosted on GitHub Pages and signed with GPG.

## Packages

### `zl`
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


---

## Configuration on Debian 13 (Trixie)

Follow either of the configuration options below to add this repository and install packages.

### Option 1: Modern DEB822 Configuration (Recommended)

1. **Download the GPG repository signing key**:
   ```bash
   sudo mkdir -p /etc/apt/keyrings
   sudo wget -O /etc/apt/keyrings/zeallab-archive-keyring.asc https://zeallab-llc.github.io/Packages/zeallab-archive-keyring.asc
   ```

2. **Add the repository source description file** `/etc/apt/sources.list.d/zeallab.sources`:
   ```ini
   Types: deb
   URIs: https://zeallab-llc.github.io/Packages/
   Suites: trixie
   Components: main
   Signed-By: /etc/apt/keyrings/zeallab-archive-keyring.asc
   ```

3. **Update the package lists and install the package**:
   ```bash
   sudo apt-get update
   sudo apt-get install -y zl
   ```

---

### Option 2: Classic Configuration Format

1. **Download the GPG repository signing key**:
   ```bash
   sudo mkdir -p /etc/apt/keyrings
   sudo wget -O /etc/apt/keyrings/zeallab-archive-keyring.asc https://zeallab-llc.github.io/Packages/zeallab-archive-keyring.asc
   ```

2. **Add the repository list entry** to `/etc/apt/sources.list.d/zeallab.list`:
   ```text
   deb [signed-by=/etc/apt/keyrings/zeallab-archive-keyring.asc] https://zeallab-llc.github.io/Packages/ trixie main
   ```

3. **Update the package lists and install the package**:
   ```bash
   sudo apt-get update
   sudo apt-get install -y zl
   ```

---

## License

All software within this repository is distributed under the GNU General Public License version 3 (GPLv3). Refer to the `LICENSE` file for details.
