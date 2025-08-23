# live-local-clonezilla

A local build system for creating a customized Clonezilla Live ISO with additional packages and custom applications.

This project automates downloading, extracting, customizing, and repacking Clonezilla Live ISO images. It is intended for **local builds** on a Linux host using `sudo` and `chroot`.

---

## Table of Contents

- [Requirements](#requirements)
- [Directory Structure](#directory-structure)
- [Scripts Overview](#scripts-overview)
- [Configuration](#configuration)
- [Building the ISO](#building-the-iso)
- [Output](#output)
- [License](#license)

---

## Requirements

- Linux host (Debian/Ubuntu/other)
- `sudo` privileges
- Required tools:
  - `bash`, `7z`, `unsquashfs`, `mksquashfs`
  - `xorriso`
  - `chroot`, `mount`, `umount`
  - `apt-get` inside the rootfs

---

## Directory Structure

```

live-local-clonezilla/
├─ build-scripts/         # Scripts for building and customizing ISO
├─ config/                # Configuration files (packages.txt)
├─ boot-files/            # Custom bootloader files (EFI, isolinux)
├─ artifacts/             # Downloaded ISO and extracted rootfs
├─ custom-apps/           # Custom apps to include in rootfs
├─ scripts/               # Helper scripts for development/testing
├─ output/                # Final ISO output
├─ rootfs/                # Extracted Clonezilla root filesystem

```

---

## Scripts Overview

### `build-scripts/build-local.sh`
Main build script. Performs the following steps:

1. Cleans previous `rootfs`
2. Downloads Clonezilla ISO
3. Extracts ISO and SquashFS
4. Customizes rootfs (installs packages, copies custom apps)
5. Repackages ISO
6. Produces final ISO in `output/`

---

### `build-scripts/customize-rootfs.sh`
Customizes the extracted rootfs:

- Mounts pseudo-filesystems (`/dev`, `/proc`, `/sys`, `/dev/pts`)
- Installs packages listed in `config/packages.txt`
- Copies custom applications from `custom-apps/opt/`
- Cleans up mounted pseudo-filesystems
- Uses `chroot` (requires `sudo`) for package installation

---

### `build-scripts/download-clonezilla-iso.sh`
- Downloads the selected Clonezilla Live ISO to `artifacts/clonezilla/`
- Verifies SHA256 checksum
- Creates a symlink `clonezilla-base.iso` for consistent naming

---

### `build-scripts/extract-clonezilla-iso.sh`
- Extracts the downloaded ISO to `artifacts/extracted/`
- Extracts SquashFS filesystem into `rootfs/`

---

### `build-scripts/repack-iso.sh`
- Repackages the customized rootfs and ISO
- Supports both BIOS (isolinux) and UEFI (GRUB) boot
- Copies custom bootloader files from `boot-files/`

---

### `build-scripts/customize-iso.sh`
- Optional extra ISO customizations (e.g., boot menu modifications)
- Can be used to override default boot settings

---

### `build-scripts/enter-rootfs.sh` & `run-in-root.sh`
- Helper scripts to manually enter or run commands inside the rootfs
- Useful for testing or debugging before repacking
- Both scripts use `sudo chroot "$ROOTFS_DIR"` environment

---

### Other Scripts

- `setup-network.sh` — optional networking setup inside rootfs
- `update-boot-files.sh` — updates bootloader files inside the ISO
- `fix-scripts-format-to-utf8-lf.sh` — normalizes line endings
- `logging.sh` — helper functions for standardized logging

---

## Configuration

- `config/packages.txt` — list of Debian/Ubuntu packages to install inside the rootfs.  
  Example:
```

isc-dhcp-client
python3
curl

````

- `custom-apps/opt/` — custom applications copied to `/opt` inside the rootfs.  

- `boot-files/` — custom EFI and isolinux boot files.

---

## Building the ISO

Run the main build script:

```bash
cd live-local-clonezilla
./build-scripts/build-local.sh
````

* You will be prompted for your `sudo` password.
* The script handles mounting, chroot, package installation, and cleanup automatically.
* Packages listed in `config/packages.txt` will be installed in the rootfs.

---

## Output

* Final ISO is located in: `output/hardclone/`
* ISO filename format: `hardclone-clonezilla-live-<version>-<timestamp>.iso`
* ISO label format: `HC-Clonezilla-<version>`

---

## License

License — see `LICENSE` file for details.
