# Lenovo ThinkPad Debian Super Optimization Suite (`thinkpad-debian-suite`)

[![Debian](https://img.shields.io/badge/Debian-Forky%20%7C%20Trixie%20%7C%20Bookworm-D70A53?logo=debian&logoColor=white)](https://www.debian.org)
[![Plymouth](https://img.shields.io/badge/Plymouth-BGRT%20Theme-blue?logo=linux&logoColor=white)](https://gitlab.freedesktop.org/plymouth/plymouth)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

This repository contains `thinkpad-debian-suite.sh`. This script combines three tools into one tool:

1. **System Optimizer** from `thinkpad-debian-optimizer` (`optimize_thinkpad.sh`).
2. **Audio Optimizer** from `thinkpad-debian-optimizer` (`optimize_audio.sh`).
3. **BGRT Plymouth and Silent Boot Tool** from `debian-bgrt-plymouth` (`debian-bgrt.sh`).

Use this script to optimize a Lenovo ThinkPad laptop that runs Debian GNU/Linux.

---

## 1. Supported Hardware and Software

This script is tuned for this hardware and software profile:

| Component | Target Specification |
| :--- | :--- |
| **Laptop** | Lenovo ThinkPad 13 2nd Gen (Intel Core i5-7200U, Intel HD Graphics 620, 1920x1080) |
| **Storage** | Intel NVMe SSD (such as Intel SSD 600p Series) |
| **Wireless** | Intel Dual Band Wireless-AC (`iwlwifi` and `iwlmvm`, such as 8265 or 8275) |
| **Audio** | Realtek ALC298 (`HDA Intel PCH`) with PipeWire and WirePlumber |
| **Firmware** | UEFI with ACPI BGRT support |
| **Operating System** | Debian 12 (Bookworm), Debian 13 (Trixie), or Debian Testing / Sid (Forky) |

---

## 2. Safety Information

> [!WARNING]
> **CAUTION:** This script changes core system files. It changes `/etc/fstab`, `/etc/default/grub`, `/etc/default/grub.d/`, `/etc/grub.d/10_linux`, `/etc/initramfs-tools/modules`, `sysctl` rules, `modprobe` options, `udev` rules, and Plymouth themes. It also rebuilds the `initramfs` image.
>
> Before you run this script:
> 1. Back up your important files.
> 2. Make sure that you know how to open the GRUB menu at boot. Hold `Esc` or `Shift` when the computer starts to open a hidden GRUB menu.
> 3. Use this script at your own risk. The author provides this software "AS IS" without warranty.

---

## 3. Prerequisites

Before you start, make sure that your system meets these conditions:

1. You have a working internet connection to install Debian packages.
2. You have `sudo` or `pkexec` access on your user account.
3. `git` is installed on your system. If `git` is not installed, run:
   ```bash
   sudo apt-get update && sudo apt-get install -y git
   ```

---

## 4. Quick Start Procedure

Follow these steps to download and run the full optimization suite.

1. Open a terminal window.
2. Clone this repository:
   ```bash
   git clone https://github.com/Antux912012/thinkpad-debian-suite.git
   ```
3. Open the repository folder:
   ```bash
   cd thinkpad-debian-suite
   ```
4. Make the script executable:
   ```bash
   chmod +x thinkpad-debian-suite.sh
   ```
5. Run the script:
   ```bash
   ./thinkpad-debian-suite.sh
   ```
6. Enter your password when `sudo` or `pkexec` asks for root permission.
7. Wait until the script finishes all steps and shows the final status report.
8. Restart the computer to apply all kernel, GRUB, Plymouth, and Early KMS changes:
   ```bash
   sudo systemctl reboot
   ```

> **NOTE:** If you copy `thinkpad-debian-suite.sh` to another folder without the `assets/` directory, the script still works. All three PNG watermark files are embedded inside the script as a fallback.

---

## 5. Commands and Options

### 5.1 Command Syntax

```text
./thinkpad-debian-suite.sh [command] [options]
```

### 5.2 Available Commands

| Command | Root Required | Description |
| :--- | :--- | :--- |
| `all [variant]` | Yes (auto-elevates) | **Default.** Runs the full suite: system optimization, network and DNS, BGRT Plymouth theme, silent boot, and audio optimization. |
| `gui` | Elevates if needed | Opens an interactive GTK4/Libadwaita window (with `zenity` and `whiptail` fallbacks) to select which optimization modules to run. |
| `network` \| `net` | Yes (auto-elevates) | Runs only the Wi-Fi, TCP/bufferbloat `sysctl`, and `systemd-resolved` DNS-over-TLS caching optimizations. |
| `system` | Yes (auto-elevates) | Runs only the ThinkPad system, NVMe, ZRAM, Wi-Fi, DNS, battery, and GRUB optimizations. |
| `audio [--apply]` | No | Runs only the Realtek ALC298 microphone and Bluetooth A2DP optimizer. |
| `bgrt [variant]` | Yes (auto-elevates) | Installs only the Fedora-style BGRT Plymouth theme and silent boot settings. |
| `silent-boot` | Yes (auto-elevates) | Applies only the hidden GRUB menu, silenced loader text, and Early KMS settings. |
| `revert-bgrt` | Yes (auto-elevates) | Removes the BGRT Plymouth theme and silent boot settings, then restores the previous configuration. |
| `custom --only ...` | If root module selected | Runs a comma-separated list of modules (`packages,nvme,power,network,dns,grub,bgrt,audio`). |
| `status` | No | Shows the current status of swap, ZRAM, THP, `sysctl`, DNS, battery thresholds, NVMe, audio, and Plymouth BGRT. |
| `help` | No | Shows the command help message. |

### 5.3 Available Options

| Option | Description |
| :--- | :--- |
| `--variant <text\|badge\|swirl>` | Selects the Plymouth watermark variant. The default value is `text`. |
| `--only <m1,m2,...>` | Used with `custom`. Runs only the listed modules (`packages,nvme,power,network,dns,grub,bgrt,audio`). |
| `--no-bgrt` | Skips the BGRT Plymouth theme and silent boot setup when you run `all`. |
| `--no-audio` | Skips the PipeWire and ALSA audio setup when you run `all`. |
| `--no-dns` | Skips `systemd-resolved` Cloudflare DoT DNS caching during `all`, `system`, or `network`. |
| `--apply` | Used with `audio`. Applies the audio settings now, and does not install the user login service. |
| `--user <username>` | Sets the desktop username for PipeWire audio configuration. |
| `-h`, `--help` | Shows the command help message. |

### 5.4 Watermark Variants

| Variant | Description | Asset File |
| :--- | :--- | :--- |
| `text` | **Default.** Circular Papirus Debian badge with white `debian` text (`180x48` px). | `assets/watermark-badge-with-text.png` |
| `badge` | Circular Papirus Debian badge without text (`64x64` px). | `assets/watermark-badge.png` |
| `swirl` | Standalone Debian swirl in Papirus `#f9548f` color (`64x64` px). | `assets/watermark-swirl.png` |

---

## 6. Common Task Procedures

### 6.1 Open the Interactive GUI Selector

To choose which optimizations to apply in a graphical window, run:

```bash
./thinkpad-debian-suite.sh gui
```

Use the switches to enable or disable each module, or select a preset (**Select All**, **Network Only**, **System + Audio (No BGRT)**, **Clear**), then click **Apply Selected**.

### 6.2 Run Network-Only Optimization

To apply only the Wi-Fi, TCP/bufferbloat `sysctl`, and `systemd-resolved` DNS-over-TLS optimizations, run:

```bash
./thinkpad-debian-suite.sh network
```

### 6.3 Run the Full Suite with a Custom Watermark

To use the minimalist `badge` watermark instead of `text`, run:

```bash
./thinkpad-debian-suite.sh all badge
```

### 6.2 Run System and Audio Optimizations Without Changing Plymouth

If you want to keep your current Plymouth boot theme, run:

```bash
./thinkpad-debian-suite.sh --no-bgrt
```

### 6.3 Run Only the Audio Optimizer

Run this command as your normal desktop user (do not use `sudo`):

```bash
./thinkpad-debian-suite.sh audio
```

This command calibrates the internal microphone and installs `thinkpad-audio-optimize.service` in `~/.config/systemd/user/`.

### 6.4 Check System and Plymouth Status

To inspect all active settings without changing any file, run:

```bash
./thinkpad-debian-suite.sh status
```

### 6.5 Revert BGRT Plymouth and Silent Boot

To restore your previous Plymouth theme, GRUB menu, and `/etc/initramfs-tools/modules`, run:

```bash
sudo ./thinkpad-debian-suite.sh revert-bgrt
```

After the command finishes, restart the computer.

---

## 7. What the Script Configures

### 7.1 Packages and Hardware Video Acceleration

1. Enables `contrib` and `non-free` in `/etc/apt/sources.list.d/debian.sources` if they are missing.
2. Installs `thermald`, `zram-tools`, `nvme-cli`, `smartmontools`, `plymouth`, `plymouth-themes`, `vainfo`, `libva-drm2`, `libva-x11-2`, and `alsa-utils`.
3. Installs `intel-media-va-driver-non-free` (or `intel-media-va-driver` as a fallback) for Intel HD Graphics 620 hardware video acceleration.

### 7.2 NVMe SSD Lifespan Protection

1. Adds `noatime,commit=60` to the root `/` `ext4` entry in `/etc/fstab` (after creating a backup) and remounts `/`.
2. Limits `systemd-journald` disk usage in `/etc/systemd/journald.conf.d/99-ssd-lifespan.conf` (`SystemMaxUse=200M`, `SyncIntervalSec=5m`).
3. Creates `/etc/udev/rules.d/60-nvme-ssd-optimize.rules` to set `queue/scheduler=none`, `queue/rq_affinity=2`, and PCI runtime power management `auto`.
4. Enables `fstrim.timer` for weekly SSD TRIM operations.

### 7.3 Memory, ZRAM, Thermal, and Battery Longevity

1. Disables kernel `zswap` and configures `zram-tools` in `/etc/default/zramswap` (`ALGO=zstd`, `PERCENT=25`, `PRIORITY=100`).
2. Sets Transparent Hugepages to `madvise` and `defer+madvise` in `/etc/tmpfiles.d/thp-madvise.conf`.
3. Enables `i915` framebuffer compression (`enable_fbc=1`), fastboot (`fastboot=1`), and `snd_hda_intel` power-save (`power_save=1`) in `/etc/modprobe.d/99-thinkpad-power.conf`.
4. Enables `thermald.service` and `power-profiles-daemon.service`.
5. Configures `suspend-then-hibernate` (`HibernateDelaySec=120min`) in `/etc/systemd/sleep.conf.d/suspend-then-hibernate.conf` and lid behavior in `/etc/systemd/logind.conf.d/lid.conf`.
6. Sets ThinkPad battery charge thresholds to `75%` start and `90%` stop, and installs `thinkpad-battery-threshold.service` to apply them at each boot.

### 7.4 Intel Wi-Fi, Network Stack, and DNS Caching

1. Loads `tcp_bbr` and `sch_fq` if available in the active kernel, and saves `tcp_bbr` in `/etc/modules-load.d/bbr.conf`.
2. Configures `iwlwifi` (`11n_disable=8 power_save=0 uapsd_disable=3 bt_coex_active=1 swcrypto=0`) and `iwlmvm` (`power_scheme=1`) in `/etc/modprobe.d/99-iwlwifi-8265.conf`.
3. Disables NetworkManager Wi-Fi power saving in `/etc/NetworkManager/conf.d/99-wifi-powersave-off.conf`.
4. Writes VM and network tuning (`vm.swappiness=100`, `net.core.default_qdisc=fq`, `net.ipv4.tcp_congestion_control=bbr`) to `/etc/sysctl.d/99-thinkpad-performance-nvme-net.conf`.
5. Writes extra TCP bufferbloat and socket hardening (`net.ipv4.tcp_notsent_lowat=131072`, `net.ipv4.tcp_rfc1337=1`, `net.core.rmem_default=262144`, `net.core.wmem_default=262144`, `net.ipv4.ip_local_port_range=16384 65535`, `net.ipv4.tcp_max_syn_backlog=4096`) to `/etc/sysctl.d/99-thinkpad-net-extra.conf`.
6. Installs `systemd-resolved` and writes `/etc/systemd/resolved.conf.d/99-cloudflare-dot.conf` to enable local DNS caching and opportunistic DNS-over-TLS (`1.1.1.2#security.cloudflare-dns.com`).

### 7.5 Fast Boot, GRUB, and BGRT Plymouth

1. Disables `NetworkManager-wait-online.service` to remove startup delay.
2. Detects the swap partition UUID with `blkid` and sets `RESUME=UUID=...` in `/etc/initramfs-tools/conf.d/resume` and `resume=UUID=...` in `/etc/default/grub`.
3. Sets `GRUB_GFXMODE=1920x1080x32,1920x1080,auto` and `GRUB_GFXPAYLOAD_LINUX=keep` in `/etc/default/grub`.
4. Installs the selected watermark to `/usr/share/plymouth/themes/spinner/watermark.png` and `/usr/share/plymouth/themes/bgrt/watermark.png`, and sets the Plymouth theme to `bgrt`.
5. Creates `/etc/default/grub.d/99-bgrt-silent.cfg` to hide the GRUB menu and add silent boot kernel parameters (`quiet splash vt.global_cursor_default=0 loglevel=3 systemd.show_status=auto rd.udev.log_level=3`).
6. Sets `quiet_boot="1"` in `/etc/grub.d/10_linux` and adds the detected GPU driver (`i915`, `xe`, `amdgpu`, `radeon`, or `nouveau`) to `/etc/initramfs-tools/modules` for Early KMS.
7. Runs `update-grub` and `update-initramfs -u -k all`.

### 7.6 Realtek ALC298 Microphone and Bluetooth Audio

1. Sets ALSA `Internal Mic Boost` to `0` and `Capture` to `65%` on card `PCH`.
2. Sets the internal microphone (`alsa_input.pci-0000_00_1f.3.analog-stereo`) as the default PipeWire source at volume `0.60`.
3. Switches connected Bluetooth (`bluez5`) headsets to `a2dp-sink-sbc_xq` or `a2dp-sink`.
4. Installs `~/.local/bin/thinkpad-audio-optimize` and enables `~/.config/systemd/user/thinkpad-audio-optimize.service`.

---

## 8. Regenerate Watermark PNG Assets

If you want to rebuild the PNG files from the Papirus SVG source:

1. Make sure that `papirus-icon-theme` and `python3-gi` are installed:
   ```bash
   sudo apt-get install -y papirus-icon-theme python3-gi gir1.2-gdkpixbuf-2.0
   ```
2. Run the generator script:
   ```bash
   python3 scripts/generate-assets.py
   ```

---

## 9. Credits and License

- **Author:** [Antonio De Gaetano (@Antux912012)](https://github.com/Antux912012)
- **Source Repositories:**
  - [thinkpad-debian-optimizer](https://github.com/Antux912012/thinkpad-debian-optimizer)
  - [debian-bgrt-plymouth](https://github.com/Antux912012/debian-bgrt-plymouth)
- **Papirus Icon Theme:** [PapirusDevelopmentTeam](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme) (GPL-3.0)
- **License:** [GNU General Public License v3.0](LICENSE)
