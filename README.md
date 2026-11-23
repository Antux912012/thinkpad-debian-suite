# Lenovo ThinkPad Debian Super Optimization Suite (`thinkpad-debian-suite`)

[![Debian](https://img.shields.io/badge/Debian-Forky%20%7C%20Trixie%20%7C%20Bookworm-D70A53?logo=debian&logoColor=white)](https://www.debian.org)
[![Plymouth](https://img.shields.io/badge/Plymouth-BGRT%20Theme-blue?logo=linux&logoColor=white)](https://gitlab.freedesktop.org/plymouth/plymouth)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

An all-in-one, idempotent **super script** (`thinkpad-debian-suite.sh`) that unifies:
1. **[`thinkpad-debian-optimizer`](https://github.com/Antux912012/thinkpad-debian-optimizer)** — System, NVMe SSD lifespan, ZRAM/zswap, Intel VA-API, battery charge thresholds, suspend-then-hibernate, Intel Wireless-AC 8265/8275, TCP BBR, and 1080p GRUB optimization.
2. **Realtek ALC298 Microphone & Bluetooth A2DP Audio Fix** — Automatic PipeWire/ALSA calibration and persistent systemd user login service (runs seamlessly in the invoking desktop user's session even when launched with `sudo`).
3. **[`debian-bgrt-plymouth`](https://github.com/Antux912012/debian-bgrt-plymouth)** — Fedora-style UEFI ACPI BGRT Plymouth boot splash with Papirus Debian watermark variants (`text`, `badge`, `swirl`), seamless flicker-free silent boot (hidden GRUB, silenced `Loading Linux...`, Early KMS), and full one-command rollback.

**Target Hardware Profile:**
- **Laptop:** Lenovo ThinkPad 13 2nd Gen (Intel Core i5-7200U, Intel HD Graphics 620, 1920x1080)
- **Storage:** Intel NVMe SSD (e.g., Intel SSD 600p Series)
- **Wi-Fi:** Intel Dual Band Wireless-AC (`iwlwifi` / `iwlmvm`, e.g., 8265 / 8275)
- **Audio:** Realtek ALC298 (HDA Intel PCH) + PipeWire / WirePlumber
- **OS:** Debian 12 (Bookworm), 13 (Trixie), or Forky / Sid

---

> [!WARNING]
> ### Experimental Status & Disclaimer of Liability
>
> This script modifies core system configuration files (`/etc/fstab`, `/etc/default/grub`, `/etc/default/grub.d/`, `/etc/grub.d/10_linux`, `/etc/initramfs-tools/modules`, `sysctl`, `modprobe`, `udev`, Plymouth themes) and rebuilds the `initramfs`.
> It is provided **"AS IS"**, without warranty of any kind. Always keep backups of important data and know how to access GRUB recovery entries (hold `Esc` or `Shift` at power-on when hidden GRUB is enabled).

---

## Quick Start

```bash
git clone https://github.com/Antux912012/thinkpad-debian-suite.git
cd thinkpad-debian-suite
chmod +x thinkpad-debian-suite.sh
./thinkpad-debian-suite.sh
```

Running `./thinkpad-debian-suite.sh` with no arguments executes the **complete suite** in one go:
1. Auto-elevates to root via `sudo` / `pkexec` while remembering your desktop user for the PipeWire audio step.
2. Installs required packages and Intel iHD VA-API hardware acceleration.
3. Optimizes NVMe SSD lifespan, ZRAM/zswap, THP, thermal/power, battery thresholds (75%–90%), and Intel Wi-Fi + TCP BBR.
4. Configures hibernation swap resume and native 1080p flicker-free GRUB.
5. Applies the Fedora-style **Debian BGRT Plymouth** boot theme (default `text` watermark) + seamless silent boot & Early KMS, rebuilding GRUB and `initramfs` **once**.
6. Calibrates the Realtek ALC298 internal microphone + Bluetooth A2DP SBC-XQ profile and installs the `thinkpad-audio-optimize.service` user login service.
7. Prints a complete health & boot status summary.

> **Standalone friendly:** All three Papirus PNG watermarks live in [`assets/`](assets/) *and* are embedded inside `thinkpad-debian-suite.sh` as an automatic fallback if you copy or run the script by itself.

---

## Commands & Options

```text
Usage:
  ./thinkpad-debian-suite.sh [command] [options]

Commands:
  all [variant]       (Default) Run FULL suite (system + BGRT Plymouth + audio)
  system              Run ThinkPad system, NVMe, ZRAM, Wi-Fi, battery & GRUB tweaks only
  audio [--apply]     Run Realtek ALC298 mic & Bluetooth A2DP optimizer (no root needed)
  bgrt [variant]      Apply Fedora-style BGRT Plymouth theme + silent boot only
  silent-boot         Apply seamless/silent GRUB + Early KMS boot optimization only
  revert-bgrt         Revert BGRT Plymouth theme & silent boot back to original state
  status              Show complete system, NVMe/ZRAM, audio, and Plymouth BGRT status
  help                Show help message

Options:
  --variant <text|badge|swirl>   Select BGRT watermark variant (default: text)
  --no-bgrt                      Skip BGRT Plymouth theme & silent boot during 'all'
  --no-audio                     Skip user-session audio optimization during 'all'
  --apply                        (With 'audio') Apply settings only; do not install service
  --user <username>              Target desktop user for PipeWire audio optimization
```

### Examples

```bash
# Run everything with the default Fedora-style Papirus badge + white 'debian' text
./thinkpad-debian-suite.sh

# Run everything with the minimalist 64x64 circular Papirus badge watermark
./thinkpad-debian-suite.sh all badge

# Run system + audio optimizations only, keeping your current Plymouth theme
./thinkpad-debian-suite.sh --no-bgrt

# Run only the Realtek ALC298 mic & Bluetooth A2DP audio fix (no sudo required)
./thinkpad-debian-suite.sh audio

# Apply only the BGRT Plymouth theme with standalone swirl watermark
sudo ./thinkpad-debian-suite.sh bgrt swirl

# Roll back BGRT Plymouth theme, watermarks, GRUB drop-in, 10_linux & Early KMS
sudo ./thinkpad-debian-suite.sh revert-bgrt

# Inspect all subsystem statuses without root
./thinkpad-debian-suite.sh status
```

---

## What Is Included

### 1. System Packages & Intel VA-API Hardware Acceleration
- Automatically enables `contrib` and `non-free` in `/etc/apt/sources.list.d/debian.sources` if needed.
- Installs `thermald`, `zram-tools`, `nvme-cli`, `smartmontools`, `plymouth`, `plymouth-themes`, `vainfo`, `libva-drm2`, `libva-x11-2`, `alsa-utils`, and `intel-media-va-driver-non-free` (with `intel-media-va-driver` fallback).

### 2. NVMe SSD Lifespan Protection
- Adds `noatime,commit=60` to the root `/` `ext4` mount in `/etc/fstab` (with automatic backup) and remounts live.
- Caps `systemd-journald` writes (`/etc/systemd/journald.conf.d/99-ssd-lifespan.conf`: `SystemMaxUse=200M`, `SyncIntervalSec=5m`).
- Sets NVMe scheduler to `none`, `rq_affinity=2`, and PCI runtime PM to `auto` (`/etc/udev/rules.d/60-nvme-ssd-optimize.rules`).
- Enables weekly `fstrim.timer`.

### 3. Performance, ZRAM/Zswap, THP, Thermal & Battery Longevity
- Configures `zstd`-compressed ZRAM swap (`PERCENT=25`, `PRIORITY=100`) and disables `zswap` (`zswap.enabled=0`) to avoid double compression.
- Sets Transparent Hugepages to `madvise` / `defer+madvise` (`/etc/tmpfiles.d/thp-madvise.conf`).
- Enables Intel HD Graphics `i915` (`enable_fbc=1`, `fastboot=1`) and `snd_hda_intel` 1s idle power-save (`/etc/modprobe.d/99-thinkpad-power.conf`).
- Enables `thermald.service` and `power-profiles-daemon.service`.
- Configures `suspend-then-hibernate` (120 min delay on battery) and intelligent lid handling (battery: `suspend-then-hibernate`, AC: `suspend`).
- Enforces ThinkPad battery charge thresholds (**75% start / 90% end**) live and at boot via `thinkpad-battery-threshold.service`.

### 4. Intel Dual Band Wireless-AC & Network Stack
- Tunes `iwlwifi` (`11n_disable=8 power_save=0 uapsd_disable=3 bt_coex_active=1 swcrypto=0`) and `iwlmvm` (`power_scheme=1`) in `/etc/modprobe.d/99-iwlwifi-8265.conf`.
- Disables NetworkManager Wi-Fi power saving (`/etc/NetworkManager/conf.d/99-wifi-powersave-off.conf`).
- Enables `tcp_bbr` + `fq` queueing, `tcp_fastopen=3`, `tcp_mtu_probing=1`, 16 MB socket buffers, and VM/writeback tuning (`/etc/sysctl.d/99-thinkpad-performance-nvme-net.conf`).

### 5. Fast Boot, 1080p GRUB & Fedora-Style Debian BGRT Plymouth
- Disables `NetworkManager-wait-online.service` (~5.5s faster userspace boot).
- Auto-detects swap partition UUID via `blkid` and configures both `/etc/initramfs-tools/conf.d/resume` and GRUB `resume=UUID=...`.
- Configures native `1920x1080` GRUB with `GRUB_GFXPAYLOAD_LINUX=keep`.
- Installs your chosen Papirus Debian watermark (`text`, `badge`, or `swirl`) into `/usr/share/plymouth/themes/spinner/watermark.png` and `/usr/share/plymouth/themes/bgrt/watermark.png`, sets the default Plymouth theme to `bgrt`, and backs up state in `/var/lib/plymouth-debian-bgrt/`.
- Eliminates all four causes of boot flicker:
  - Hidden GRUB menu (`/etc/default/grub.d/99-bgrt-silent.cfg`) — press/hold `Esc` or `Shift` at boot whenever you need the menu.
  - Silenced `"Loading Linux..."` loader text (`quiet_boot="1"` in `/etc/grub.d/10_linux`).
  - Hidden blinking console cursor and quiet kernel/udev logs (`vt.global_cursor_default=0 loglevel=3 systemd.show_status=auto rd.udev.log_level=3`).
  - Early KMS GPU module (`i915`, `xe`, `amdgpu`, `radeon`, or `nouveau`) added to `/etc/initramfs-tools/modules`.

### 6. Realtek ALC298 Microphone & Bluetooth A2DP Audio Optimizer
- Calibrates `PCH` ALSA gains (`Internal Mic Boost=0`, `Capture=65%`) and PipeWire input volume (`0.60`) to eliminate +60 dB internal mic clipping.
- Sets the built-in mic as default PipeWire input and switches Bluetooth (`bluez5`) headsets back to high-fidelity A2DP (`a2dp-sink-sbc_xq` / `a2dp-sink`).
- Installs `~/.local/bin/thinkpad-audio-optimize` and enables `~/.config/systemd/user/thinkpad-audio-optimize.service` to re-apply automatically at every login.

---

## Watermark Variants

| Variant | Description | Asset |
| :--- | :--- | :--- |
| **`text`** *(Default)* | Fedora style: circular Papirus Debian badge + white `debian` typography (`180x48`) | `assets/watermark-badge-with-text.png` |
| **`badge`** | Minimalist: circular Papirus Debian badge alone (`64x64`) | `assets/watermark-badge.png` |
| **`swirl`** | Standalone Debian swirl in Papirus `#f9548f` (`64x64`) | `assets/watermark-swirl.png` |

To regenerate PNG assets from the Papirus SVG icon theme:
```bash
python3 scripts/generate-assets.py
```

---

## Credits & License

- **Author / Maintainer:** [Antonio De Gaetano (@Antux912012)](https://github.com/Antux912012)
- **Merged Repositories:**
  - [Antux912012/thinkpad-debian-optimizer](https://github.com/Antux912012/thinkpad-debian-optimizer)
  - [Antux912012/debian-bgrt-plymouth](https://github.com/Antux912012/debian-bgrt-plymouth)
- **Papirus Icon Theme:** [PapirusDevelopmentTeam](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme) (GPL-3.0)
- **License:** [GNU General Public License v3.0](LICENSE)
