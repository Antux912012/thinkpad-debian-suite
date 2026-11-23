#!/usr/bin/env bash
# ==============================================================================
# Lenovo ThinkPad Debian Super Optimization Suite (thinkpad-debian-suite.sh)
#
# Combines:
#   1. ThinkPad System, NVMe, ZRAM, VA-API, Battery, Wi-Fi & GRUB Optimizer
#      (from Antux912012/thinkpad-debian-optimizer)
#   2. Realtek ALC298 Microphone & Bluetooth A2DP Audio Optimizer + User Service
#      (from Antux912012/thinkpad-debian-optimizer)
#   3. Fedora-Style Debian BGRT Plymouth Theme + Papirus Logo & Silent Boot
#      with Full Rollback (from Antux912012/debian-bgrt-plymouth)
#
# Target Hardware Profile:
#   - Lenovo ThinkPad 13 2nd Gen (i5-7200U / Intel HD Graphics 620 / 1920x1080)
#   - Intel NVMe SSD (e.g., Intel SSD 600p Series)
#   - Intel Dual Band Wireless-AC (iwlwifi / iwlmvm, e.g., 8265 / 8275)
#   - Realtek ALC298 (HDA Intel PCH) + PipeWire / WirePlumber
#   - UEFI ACPI BGRT Firmware + Debian (Bookworm / Trixie / Forky / Sid)
#
# License: GNU General Public License v3.0 (GPL-3.0)
# ==============================================================================
set -euo pipefail

# Ensure sbin directories are on PATH (Debian non-root shells often omit /usr/sbin)
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PATH}"

# ------------------------------------------------------------------------------
# Paths & Constants
# ------------------------------------------------------------------------------
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
ASSETS_DIR="${SCRIPT_DIR}/assets"

# Plymouth BGRT state & system paths (compatible with debian-bgrt-plymouth)
STATE_DIR="/var/lib/plymouth-debian-bgrt"
STATE_FILE="${STATE_DIR}/state.env"
BACKUP_DIR="${STATE_DIR}/backup"
SPINNER_THEME_DIR="/usr/share/plymouth/themes/spinner"
BGRT_THEME_DIR="/usr/share/plymouth/themes/bgrt"
GRUB_SILENT_CFG="/etc/default/grub.d/99-bgrt-silent.cfg"
GRUB_10_LINUX="/etc/grub.d/10_linux"
INITRAMFS_MODULES="/etc/initramfs-tools/modules"

# Audio calibration parameters (Realtek ALC298 / HDA Intel PCH)
AUDIO_CARD_NAME="PCH"
AUDIO_INTERNAL_MIC_NODE="alsa_input.pci-0000_00_1f.3.analog-stereo"
AUDIO_MIC_BOOST=0          # 0..3 (x10 dB). 0 = no analog boost -> no clipping
AUDIO_CAPTURE_LEVEL="65%"  # ALSA 'Capture' hardware gain
AUDIO_SOURCE_VOLUME="0.60" # PipeWire software volume for internal mic

# Runtime defaults
ACTION="all"
BGRT_VARIANT="text"
SKIP_BGRT=0
SKIP_AUDIO=0
AUDIO_APPLY_ONLY=0
TARGET_USER=""

# ------------------------------------------------------------------------------
# Terminal Styling & Logging
# ------------------------------------------------------------------------------
if [ -t 1 ]; then
    BOLD=$'\033[1m'
    GREEN=$'\033[1;32m'
    YELLOW=$'\033[1;33m'
    RED=$'\033[1;31m'
    BLUE=$'\033[1;34m'
    CYAN=$'\033[1;36m'
    RESET=$'\033[0m'
else
    BOLD=""
    GREEN=""
    YELLOW=""
    RED=""
    BLUE=""
    CYAN=""
    RESET=""
fi

log_info()  { printf '%s[INFO]%s %s\n' "$BLUE" "$RESET" "$*"; }
log_ok()    { printf '%s[OK]%s %s\n' "$GREEN" "$RESET" "$*"; }
log_warn()  { printf '%s[WARN]%s %s\n' "$YELLOW" "$RESET" "$*"; }
log_error() { printf '%s[ERROR]%s %s\n' "$RED" "$RESET" "$*" >&2; }
log_step()  { printf '\n%s==>%s %s%s%s\n' "$CYAN" "$RESET" "$BOLD" "$*" "$RESET"; }

# ------------------------------------------------------------------------------
# Embedded Fallback PNG Watermark Assets (used if assets/ directory is absent)
# ------------------------------------------------------------------------------
extract_embedded_watermark() {
    local variant="$1"
    local dest="$2"
    case "$variant" in
        badge)
            base64 -d <<'__B64_WATERMARK_BADGE__' > "$dest"
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
9zj+A2nrOifwoXeIAAAAAElFTkSuQmCC
__B64_WATERMARK_BADGE__
            ;;
        swirl)
            base64 -d <<'__B64_WATERMARK_SWIRL__' > "$dest"
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
SUVORK5CYII=
__B64_WATERMARK_SWIRL__
            ;;
        text|*)
            base64 -d <<'__B64_WATERMARK_TEXT__' > "$dest"
iVBORw0KGgoAAAANSUhEUgAAALQAAAAwCAYAAAC47FD8AAANzklEQVR4nO2dCXAUVRrH/91z5iIH
OSDcCMrhhQqIcnngBYig4oFyqKiUpeDBFrqWq7vllhcquoIiIpQILKirgoLsAoJEQFA8QFAOgQSS
EJKZJJO5p3u/b2YCzWSO7hy7kPSv6qs+33s9M1+//t7/e52I0NFpRojQ0WlG6A6t06zQHVqnWWFE
EyBPXZznk3ydBIOQGtwOyA6TaDokzLqzFDo6TYiARsA9felZguy7SwhgqOzzXygEpAz4A+TJilaM
BsgG0S6YDTtkAV/LJsMi6wvjDkBHpxFpkEO7H1s4AhJmiG7fANnhFuHxnXTieC1azRBSLBItv5Ug
vWB9feIX0NFpBOrl0N7H3rtAlgxzhGrPALnKRU6cyItjtS5AaJUEKc1aIFikKZYXJ/0CHZ0GoNmh
vdOXPCRXVs+E3WmBVE9HjkQUIGem+KjXfs7y6vjnoaNTT1Q7tHz/OyaP1bJYsNXcApcXTUKyBYHM
pOVJLu84Ye4DPujoaESVQ7Mzu62mL8SymmHw+aEJgxgcEAbjazWYjJBz0tZY3J4RulPraEWVbOey
mBYbjjmGBZULFQg5rSAO7QVYyDkPHIPkcEMkx5Z2FVHMkuCGoBtGOFZ1jSs3dRFt3QYdHQ0k7KEd
j8x/0lRW83c1PbPQOhXiHZfBMLBHqGeOgJQQSOt2AbYaBFb9CASk2JWZ6WbITptufWPiK9DRUUlc
hw6qGeWe71DjMSMB4rDzgs4spiWFdpDy4SmpgLe8CrIvAHNuBqz5rYPKBiOVVkKauxbSz4djV5pq
9SAz6WLLaxN3oYmQZflCWhjCm3sFQahCI0D1XqzY3EP11kAjVIeZyjXRgKV5Ejfk8Dv8sw1qnPnW
/jCOHXBiu+rHfTj69kpYiuwwCgYSMQT4pADc6Rak33Qp2t4yBGJeOoQnRwGvrIT0/R/RK3a4LX6z
+DatDULTsZ4sI7x+PdlqNBByRL5rtyt2XUq2VUN5itewgqwzrf+LlreRY6uL91o4Medy1Dz8/khD
lecyJEDo3+2EM/sqHdhz30xUP7MUXcpltEvKQJ41DTmWVOQnpaOr1wrL4q3Y/8xCyBSPCzRYFKde
ByG3Vcz6jdWege5p712PlsUTZF0R+n1uJrsaOqqI6dBSVc2fYg0COVYOBisUJwsTBwf3HV/7Aw5O
noUulWLQgYUY0Uyq0YI2v5aj8K3PQheQRHL2+IGICYUrPrt7Blo2jST4N3+iOrRr2pLOJq8Us3f2
HK8MfsXCqIthzG6F0s8KEHhzNTrJKTEdWYlJNKDVxn2o+b0wuO32eaMOImsxe6SBrieWdUHL4WWy
38l4JL6MbC10VBHVi5z24xMEXyCmh5lNFFZTytp4S39Ubv8NwoJvkGlKrnsi+bZ4URcYbiflY3gf
COknz0kWzahaXhDa2F8K2RDnRvD5RVd56Z1oIVC8vJvsHFq10lKPnzUQ1WlFr++KeIUCggxp0DkQ
KAniWb8TGUZr3ZPYmR+8GvYMIw7/cy1KPt0EZzrdCEknx5hJv5WFTs1Ko5haitckBE/8a2qO6I6s
nagqh1k2XEBRdMxCBp8EqV9X+CqqYNpKCoVQtxrh+gtxdPUWZO2vRCuRpDwT1XjIhgDFKgYhdB9Z
nX6Kjx0QM1MgJpgXYpENfVBPSCngBjlJcwdZdzJ2lJ1kc1SW57twPNloMg59WObbT/YJ2UJyvEQZ
zSSqYyotR5J1JGNpkNWV16nskSjtXU6LqeFNF50zIeI46Z8giQhDyHqS8TZfw0GyNWTvUZnKKPXe
RAt+0nEocw+ZNby8liyPzEbGMx/n1EdmPB2o44nyw/NzvKVVGQkL5mehassepEZxZs4Qujuko/XK
ymC8XIsY1KCFYNKEM4a8HZwqzfp0AgwBOYuvTXjznjJogH5EllDY8a6KONSbbCwSDLiofDeEJLQe
EYfORkjmu5fOuYEcwBanmuVk2RH7WKd+gMreTGX/HXGMnf7W8Ho12QTF9XC5TQg5YyQcprBzTqXz
rqV690Qc76Gol28qdvC8iHOGkt1F5Qc3lib/v6ROyFFUbu+iZhZdwOWFYIt+EwfyM+A7fPwUZz7l
eG2rJNsZUqyopjg8IXRNh8srOkI7C1DXmWt/KL6fYo4V6EfNpAU7Ww9Fuf8gpDHXfkmsMSfq6bMj
2q0ljewjaqcT1MNJJuUToYLsKE59pPL3tCz8ZIrFA6jrzLXQExp/wxlInQ8sOV1pUIvdGXW3nzvh
3BidPB0z+EO+IBuFYOZQ3kAdiSm68yuRfb50aIB+UE7IjFbsWknWgXoerqct2cIEVTxJ1jm8zr1d
Tyo7jKwvrd+uOG8stdU1Tj38hMgPt5tP9oHiGD9BVMuSVIebFo8jFHKk0XZrsna0nkX2quLU8xA/
IRUIn38+WS7ZDQjdGLXcneCGOC2pc8FutweqkCSQEhL90NFyGLu3jXpMTiHd2RhqVhjTDzV7i5Ba
WkMdcOKngtuhOawbp1gvJhtLP35RsG1BKKHFJIQe6XWvM5TtU8auf6UyJ35wWmc57fvaTYTi2Vi8
ROcXh8sVh+vdojg+JtyeKqiOd8k+J3Mo9nHMzAkZ5Wttl8SphpWUx8l+ISsjW0X7nlYc56dTe5xh
1AmAXbK7WkU5SB4fDFmpUY9ZvTJc5NQpF3WG/MPB4D6BUt0szUlHKkKxc14GhCE9cfzxedR1iZAD
UsI2fX5Za0zXV7HODuBSHqRt8iM5lpJwFkI9Vy1n07n3IzZtoJJwu3MRClcQbofLF0MD4ZuAB7n8
dEgPm/LzZEIbOyK21T+tTxPqOHSJ017YM61twoKBahfELrnRD3bMhnvJJlgfGQGD2wf51yNwF5cH
ky5miqvFAd0h3DUQh974BO0doY5JUJELO+yzFUEbyoGY1rKRH+7ZBOerfLSdYF/ENjufKocOx/ZP
IaS85MY5VesbSe4Glv+/U8ehr/tmbqljzEy7SRTjKh2e34uQdnnv6McOHkNqkgm2TwrQevwVMFY4
YdhbEnwjBRd0hLvcjqIZ89CeH5Ji4tiZ8ctSxfCvZx+DNpROlgdtRA4QPiWL1/42aCPy8abq6UPO
zLEyhyvdw7uOk31FtpuMFSCW+3qhhRJNh5Zq/O6fM8zJg+MVlHcfhfnWwfBfcx6kNae+22rl0NwV
gHVHEUqdqxCgmNnaIQfufTbqub9CK3rwd7GkaPozN1U+90+IJ45H5yBO/vBDeZBDj3u1dXAsynpt
7Xe0gcq+jsbjUsW6HacOyOJxH05+Ju7l+yklQ5YB0YIdOqpLlXudG5EA4y9FlFiphnEyKWL50Tvz
FKMZrffZkflrGaxf7ULuz8fQVUpBNjuzRiq8roTXFAXlHIhzERo0nYB+fB40Rb2YsAa7XrHrqbAm
XR9GRLTLyZCHFbu+1HCjKa+BR8l2Rb0cImhSgpobUR16U/mBpTLkuF9wMnVcttWhp2ygd7uY5xlp
wJdkMCHZYA6u1xNpW3nhcmhnPpkyY/Yi/egFZK+RfUzbPJnEFKf8XxDqpZkcsu1U7hXuBcmGk00m
W0D2DOLzNJ3zQ7jdpbT9HU4O2FhTfgnqKVSss178GdXJyZ1Hw5+nP1owUT3s/m1Ldlf6XFsSFZZX
7IDPVg1xYA80JTavc/PEbQt3ayzGvSzHlKxMKEf+PItwGtkYMk5p74pTfjNCCYjaRAb3fqwBf4SQ
ps1KBUtwkxCb2ji+T7hdTsHXxs88FH6U2vkJ6nkfp96knE6fh5CmPCDiWIsjVpcp/Wg78gYSkOk3
oOTdVbD06gCBJLqm4ifbEY5dtcbPQcJ6MScNIh2X409OfV+HOAoFledenns9To64opzC6ska6iGT
Y1TBcyW4B49MjbMTD6f634IGwjo6Zz4jJTa+ttkI9dputFDiyTLmkhuf35hpTo77CHMFfPBMvBzZ
V/RBYMYSyMcaN/1PvXNBm8//fCWtNvjdOnI61pY5U8d/NHKfhri1tjz36DyHg+VAdtDScIJGTVme
e8HxLw84DlG5QjQQqjM7fD3swLsjdfaWSFydcW7fO4bc3bHvGpIG4r5XaAu4YXr0BrTKz4X8jzWQ
iyrQGFD20LPg0JarpmxfVgAdHRXEFYFXHN1ZeGO73pY21vS4El6SaER1wS6426QhddJVkL/Zw6+h
oKHsqCx6fvSmeR9CfwVJRyVqMkHJB4Y/u7hdUvqoRCeSVgz7OVnoNHkkBNKppQ8L4v/tjTgUOu2f
dvvyOZ6L4YSOjkrUpOl864t3rxvdvs8lpCvHfa/PYjAitcKD4pWbUel0IOX8rjDwGyoOCvH86h27
zONYN3rDnAklXkeLHrHraEd1rr53Sk6bFUMfeltNT82Qjo0avzc4f4N1aFFQ1xT3zKM2zJ6yq6ZM
1WBLR0eJ1sknGQVXTnviosyO0xMNFLXCA8DttkMvD1o3ayYU2S8dHS2omxl0Evf8P7Z8axaNm3un
t+lGPW+jzJclae7bWfu+fnDC1kU88f2MfJdN5/SgIdMDcxb2Hzfy2rxe95JWzRNtNOW1ObVe4XVu
WVO8Z97EbYs466bpXUEdnWg0dL4rO3HrKd0G9RrXse+IrqlZ/dJNSecaBTEr2sk8BdTude78w1mx
9YPD3698Z+9GTmeXo55ZQB2dSBpzAjfH1Px+XMrNHfrk9Mvo1D7TYg2+8WDzuKu/sx8q+rhwB/fC
/NoQvxWj/1VNnUbnjHsjQUcnHvp/ktVpVugOrdOs0B1ap1nxXxshzXf6Jo9yAAAAAElFTkSuQmCC
__B64_WATERMARK_TEXT__
            ;;
    esac
}

# ------------------------------------------------------------------------------
# Help & Usage
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
${BOLD}Lenovo ThinkPad Debian Super Optimization Suite${RESET}

${BOLD}Usage:${RESET}
  $0 [command] [options]

${BOLD}Commands:${RESET}
  ${GREEN}all${RESET} [variant]       (Default) Run FULL suite:
                        1) ThinkPad system, NVMe, ZRAM, VA-API, battery, Wi-Fi & GRUB
                        2) Fedora-style BGRT Plymouth theme + Papirus logo & silent boot
                        3) Realtek ALC298 mic & Bluetooth A2DP audio optimizer + user service
  ${GREEN}system${RESET}              Run ThinkPad system, NVMe, ZRAM, Wi-Fi, battery & GRUB tweaks only
  ${GREEN}audio${RESET} [--apply]     Run Realtek ALC298 mic & Bluetooth A2DP optimizer (no root needed)
  ${GREEN}bgrt${RESET} [variant]      Apply Fedora-style BGRT Plymouth theme + silent boot only
  ${GREEN}silent-boot${RESET}         Apply seamless/silent GRUB + Early KMS boot optimization only
  ${GREEN}revert-bgrt${RESET}         Revert BGRT Plymouth theme & silent boot back to original state
  ${GREEN}status${RESET}              Show complete system, NVMe/ZRAM, audio, and Plymouth BGRT status
  ${GREEN}help${RESET}                Show this help message

${BOLD}BGRT Watermark Variants:${RESET}
  ${GREEN}text${RESET}   (Default) Fedora style: circular Papirus Debian badge + white 'debian' text
  ${GREEN}badge${RESET}  Minimalist: circular Papirus Debian badge alone (64x64)
  ${GREEN}swirl${RESET}  Standalone Debian swirl in Papirus #f9548f

${BOLD}Options:${RESET}
  --variant <text|badge|swirl>   Select BGRT watermark variant (default: text)
  --no-bgrt                      Skip BGRT Plymouth theme & silent boot during 'all'
  --no-audio                     Skip user-session audio optimization during 'all'
  --apply                        (With 'audio') Apply audio settings only; do not install service
  --user <username>              Target normal desktop user for PipeWire audio optimization
  -h, --help                     Show this help message

${BOLD}Examples:${RESET}
  ./thinkpad-debian-suite.sh                     # Run full suite (auto-elevates via sudo)
  ./thinkpad-debian-suite.sh all badge           # Full suite with minimalist badge watermark
  ./thinkpad-debian-suite.sh --no-bgrt           # System + audio only, keep current Plymouth
  ./thinkpad-debian-suite.sh audio               # Audio calibration + login service only (no root)
  sudo ./thinkpad-debian-suite.sh bgrt swirl     # Apply BGRT Plymouth with swirl watermark only
  sudo ./thinkpad-debian-suite.sh revert-bgrt    # Revert BGRT Plymouth & silent boot
  ./thinkpad-debian-suite.sh status              # Inspect all subsystem statuses (no root)
EOF
}

# ------------------------------------------------------------------------------
# Root Elevation & Target Desktop User Detection
# ------------------------------------------------------------------------------
detect_target_user() {
    if [ -n "${TARGET_USER:-}" ]; then
        echo "$TARGET_USER"
        return 0
    fi
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        echo "$SUDO_USER"
        return 0
    fi
    if [ -n "${PKEXEC_UID:-}" ] && [ "$PKEXEC_UID" != "0" ]; then
        getent passwd "$PKEXEC_UID" 2>/dev/null | cut -d: -f1 || true
        return 0
    fi
    if [ "$(id -u)" -ne 0 ]; then
        id -un
        return 0
    fi
    # Fallback: first non-root active graphical/user session via loginctl
    if command -v loginctl >/dev/null 2>&1; then
        loginctl list-users --no-legend 2>/dev/null | awk '$1 >= 1000 { print $2; exit }' || true
    fi
}

ensure_root() {
    if [ "$(id -u)" -ne 0 ]; then
        local caller_user
        caller_user="$(id -un)"
        log_info "Root privileges required for '${ACTION}'. Elevating..."
        local extra_args=()
        if [ -z "${TARGET_USER:-}" ] && [ "$caller_user" != "root" ]; then
            extra_args+=(--user "$caller_user")
        fi
        if command -v sudo >/dev/null 2>&1; then
            exec sudo bash "$SCRIPT_PATH" "${ORIG_ARGS[@]}" "${extra_args[@]}"
        elif command -v pkexec >/dev/null 2>&1; then
            exec pkexec bash "$SCRIPT_PATH" "${ORIG_ARGS[@]}" "${extra_args[@]}"
        else
            log_error "Please run this command as root (sudo/pkexec not found)."
            exit 1
        fi
    fi
}

detect_gpu_driver() {
    if ! command -v lspci >/dev/null 2>&1; then
        return 0
    fi
    lspci -k 2>/dev/null | awk '
        BEGIN { in_gpu = 0 }
        /^[0-9a-fA-F]+:[0-9a-fA-F]+\.[0-9a-fA-F]/ {
            line = tolower($0)
            in_gpu = (line ~ /vga|3d|display/)
            next
        }
        in_gpu && /Kernel driver in use:/ {
            print $NF
            exit
        }
    ' || true
}

# ------------------------------------------------------------------------------
# PART 1: ThinkPad System, NVMe, ZRAM, VA-API, Battery, Wi-Fi & GRUB Optimizer
# ------------------------------------------------------------------------------
install_system_packages() {
    log_step "[System 1/5] Installing System Optimization, NVMe, VA-API, Thermal, Audio & Plymouth Packages"
    export DEBIAN_FRONTEND=noninteractive

    # Enable contrib and non-free components if using modern deb822 debian.sources
    if [ -f /etc/apt/sources.list.d/debian.sources ] && ! grep -qE 'Components:.*(^|[[:space:]])non-free([[:space:]]|$)' /etc/apt/sources.list.d/debian.sources; then
        log_info "Enabling contrib and non-free components in /etc/apt/sources.list.d/debian.sources..."
        sed -i 's/Components: main non-free-firmware/Components: main contrib non-free non-free-firmware/g' /etc/apt/sources.list.d/debian.sources || true
    fi

    apt-get update -qq
    apt-get install -y -qq \
        thermald zram-tools nvme-cli smartmontools \
        plymouth plymouth-themes \
        vainfo libva-drm2 libva-x11-2 \
        alsa-utils
    apt-get install -y -qq intel-media-va-driver-non-free \
        || apt-get install -y -qq intel-media-va-driver \
        || true
    log_ok "System packages installed."
}

optimize_nvme_ssd() {
    log_step "[System 2/5] Optimizing NVMe SSD Lifespan (/etc/fstab, Journald, Udev, Fstrim)"

    # Dynamically add noatime,commit=60 to the root (/) ext4 entry in /etc/fstab if not present
    if awk '$2 == "/" && $3 == "ext4" && $4 !~ /noatime/ { found=1 } END { exit !found }' /etc/fstab; then
        cp -a /etc/fstab "/etc/fstab.bak.$(date +%Y%m%d%H%M%S)"
        awk '
        $2 == "/" && $3 == "ext4" && $4 !~ /noatime/ {
            $4 = "noatime,commit=60," $4
        }
        { print }
        ' /etc/fstab > /etc/fstab.tmp && mv /etc/fstab.tmp /etc/fstab
        log_info "Updated /etc/fstab with noatime,commit=60 for root ext4 mount."
    else
        log_info "/etc/fstab root mount already configured (or non-ext4)."
    fi

    systemctl daemon-reload
    mount -o remount,noatime,commit=60 / 2>/dev/null || true

    # Cap systemd-journald writes to protect SSD from log wear
    mkdir -p /etc/systemd/journald.conf.d
    cat <<'EOF' > /etc/systemd/journald.conf.d/99-ssd-lifespan.conf
[Journal]
SystemMaxUse=200M
SystemMaxFileSize=50M
RuntimeMaxUse=64M
SyncIntervalSec=5m
EOF
    systemctl restart systemd-journald || true

    # NVMe udev rule: none scheduler, rq_affinity=2, PCI runtime PM auto
    cat <<'EOF' > /etc/udev/rules.d/60-nvme-ssd-optimize.rules
ACTION=="add|change", KERNEL=="nvme[0-9]*n[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="none", ATTR{queue/rq_affinity}="2"
ACTION=="add", SUBSYSTEM=="pci", ATTR{class}=="0x010802", ATTR{power/control}="auto"
EOF
    udevadm control --reload-rules && udevadm trigger --subsystem-match=block || true

    # Enable weekly TRIM timer
    systemctl enable --now fstrim.timer || true
    log_ok "NVMe SSD lifespan optimizations applied."
}

optimize_power_zram_battery() {
    log_step "[System 3/5] Optimizing Performance, RAM/ZRAM, THP, Thermal & Battery Life"

    # Disable kernel zswap live so it does not double-compress pages before ZRAM
    if [ -w /sys/module/zswap/parameters/enabled ]; then
        echo N > /sys/module/zswap/parameters/enabled 2>/dev/null || true
    fi

    # Configure zram-tools for fast zstd compressed RAM swap
    if [ -f /etc/default/zramswap ] && [ ! -f /etc/default/zramswap.bak ]; then
        cp -a /etc/default/zramswap /etc/default/zramswap.bak || true
    fi
    cat <<'EOF' > /etc/default/zramswap
ALGO=zstd
PERCENT=25
PRIORITY=100
EOF
    systemctl enable zramswap.service || true
    systemctl restart zramswap.service || true

    # Transparent Hugepages (THP) to madvise to prevent desktop compaction stalls
    mkdir -p /etc/tmpfiles.d
    cat <<'EOF' > /etc/tmpfiles.d/thp-madvise.conf
# Set Transparent Hugepages to madvise to prevent desktop latency/memory bloat
w /sys/kernel/mm/transparent_hugepage/enabled - - - - madvise
w /sys/kernel/mm/transparent_hugepage/defrag - - - - defer+madvise
EOF
    systemd-tmpfiles --create /etc/tmpfiles.d/thp-madvise.conf 2>/dev/null || true

    # Intel HD Graphics 620 (i915) & Sunrise Point-LP HD Audio power saving
    mkdir -p /etc/modprobe.d
    cat <<'EOF' > /etc/modprobe.d/99-thinkpad-power.conf
# Intel HD Graphics (Kaby Lake / Skylake+): enable framebuffer compression & fastboot
options i915 enable_fbc=1 fastboot=1

# Intel HDA Audio: enter power-save after 1s idle
options snd_hda_intel power_save=1 power_save_controller=Y
EOF

    # Apply audio power save live
    echo 1 > /sys/module/snd_hda_intel/parameters/power_save 2>/dev/null || true
    echo Y > /sys/module/snd_hda_intel/parameters/power_save_controller 2>/dev/null || true

    # Enable Intel thermald and power-profiles-daemon
    systemctl enable --now thermald.service || true
    systemctl enable --now power-profiles-daemon.service || true

    # Configure systemd suspend-then-hibernate (hibernate after 120min on battery)
    mkdir -p /etc/systemd/sleep.conf.d
    cat <<'EOF' > /etc/systemd/sleep.conf.d/suspend-then-hibernate.conf
[Sleep]
AllowSuspend=yes
AllowHibernation=yes
AllowSuspendThenHibernate=yes
HibernateDelaySec=120min
EOF

    # Configure logind lid switch: suspend-then-hibernate on battery, suspend on AC
    mkdir -p /etc/systemd/logind.conf.d
    cat <<'EOF' > /etc/systemd/logind.conf.d/lid.conf
[Login]
HandleLidSwitch=suspend-then-hibernate
HandleLidSwitchExternalPower=suspend
EOF
    systemctl kill --signal=SIGHUP systemd-logind.service 2>/dev/null || true

    # Configure ThinkPad battery charge thresholds (75% start / 90% end)
    for bat in /sys/class/power_supply/BAT*; do
        if [ -f "$bat/charge_control_end_threshold" ]; then
            if [ -f "$bat/charge_control_start_threshold" ]; then
                echo 50 > "$bat/charge_control_start_threshold" 2>/dev/null || true
            fi
            echo 90 > "$bat/charge_control_end_threshold" 2>/dev/null || true
            if [ -f "$bat/charge_control_start_threshold" ]; then
                echo 75 > "$bat/charge_control_start_threshold" 2>/dev/null || true
            fi
        fi
    done

    cat <<'EOF' > /etc/systemd/system/thinkpad-battery-threshold.service
[Unit]
Description=Set Lenovo ThinkPad Battery Charge Thresholds (75%-90%)
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'for bat in /sys/class/power_supply/BAT*; do [ -w "$bat/charge_control_start_threshold" ] && echo 50 > "$bat/charge_control_start_threshold" || true; [ -w "$bat/charge_control_end_threshold" ] && echo 90 > "$bat/charge_control_end_threshold" || true; [ -w "$bat/charge_control_start_threshold" ] && echo 75 > "$bat/charge_control_start_threshold" || true; done'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable thinkpad-battery-threshold.service || true
    log_ok "ZRAM, THP, thermal, lid sleep & battery threshold optimizations applied."
}

optimize_wifi_network() {
    log_step "[System 4/5] Optimizing Intel Dual Band Wireless-AC & Network Stack"

    # Load TCP BBR congestion control module
    modprobe tcp_bbr || true
    mkdir -p /etc/modules-load.d
    echo "tcp_bbr" > /etc/modules-load.d/bbr.conf

    # Configure iwlwifi & iwlmvm for Intel Wireless-AC (8265/8275+)
    mkdir -p /etc/modprobe.d
    cat <<'EOF' > /etc/modprobe.d/99-iwlwifi-8265.conf
# Intel Dual Band Wireless-AC optimizations:
# - 11n_disable=8: Enables aggressive TX AMPDU frame aggregation for higher throughput
# - power_save=0: Disables link-layer power save to prevent latency spikes and drops
# - uapsd_disable=3: Disables U-APSD power save on BSS & P2P to improve AP compatibility & speed
# - bt_coex_active=1: Maintains Bluetooth/Wi-Fi coexistence
options iwlwifi 11n_disable=8 power_save=0 uapsd_disable=3 bt_coex_active=1 swcrypto=0

# Set iwlmvm power_scheme=1 (Continuously Active / CAM) instead of 2 (Balanced) to eliminate ping spikes
options iwlmvm power_scheme=1
EOF

    # Disable NetworkManager Wi-Fi power saving (2 = disable)
    mkdir -p /etc/NetworkManager/conf.d
    cat <<'EOF' > /etc/NetworkManager/conf.d/99-wifi-powersave-off.conf
[connection]
wifi.powersave = 2
EOF
    nmcli general reload 2>/dev/null || systemctl reload NetworkManager 2>/dev/null || true
    for iface in /sys/class/net/wl*; do
        if [ -e "$iface" ] && command -v iw >/dev/null 2>&1; then
            iw dev "$(basename "$iface")" set power_save off 2>/dev/null || true
        fi
    done

    # Configure Sysctl for VM, NVMe Writeback, Power, and TCP BBR + FQ Network Stack
    mkdir -p /etc/sysctl.d
    cat <<'EOF' > /etc/sysctl.d/99-thinkpad-performance-nvme-net.conf
# --- CPU & Power Saving ---
kernel.nmi_watchdog = 0

# --- Memory & NVMe SSD Lifespan (16GB RAM + ZRAM) ---
vm.swappiness = 100
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
vm.vfs_cache_pressure = 50
vm.dirty_background_ratio = 5
vm.dirty_ratio = 15
vm.dirty_writeback_centisecs = 1500
vm.page-cluster = 0

# --- Network & Intel Wi-Fi Throughput (TCP BBR + Fair Queueing) ---
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_slow_start_after_idle = 0
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 131072 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.netdev_max_backlog = 16384
EOF
    sysctl --system >/dev/null
    log_ok "Intel Wi-Fi, TCP BBR/FQ & VM sysctl optimizations applied."
}

configure_thinkpad_grub_and_boot() {
    local set_fallback_theme="${1:-1}"
    log_step "[System 5/5] Configuring Fast Boot, Hibernation Resume & 1080p Flicker-Free GRUB"

    # Eliminate ~5.5s userspace boot stall from NetworkManager-wait-online
    systemctl disable NetworkManager-wait-online.service 2>/dev/null || true

    if [ "$set_fallback_theme" -eq 1 ] && [ -x /usr/sbin/plymouth-set-default-theme ]; then
        if /usr/sbin/plymouth-set-default-theme -l | grep -qx "bgrt"; then
            /usr/sbin/plymouth-set-default-theme bgrt || true
        else
            /usr/sbin/plymouth-set-default-theme ceratopsian || true
        fi
    fi

    # Dynamically detect swap partition UUID for reliable hibernation resume
    local swap_uuid=""
    local resume_cmdline=""
    swap_uuid="$(blkid -t TYPE=swap -s UUID -o value 2>/dev/null | head -n 1 || true)"
    if [ -n "$swap_uuid" ]; then
        resume_cmdline=" resume=UUID=${swap_uuid}"
        mkdir -p /etc/initramfs-tools/conf.d
        echo "RESUME=UUID=${swap_uuid}" > /etc/initramfs-tools/conf.d/resume
        log_info "Detected swap partition UUID=${swap_uuid} for hibernation resume."
    else
        log_warn "No swap partition detected via blkid; skipping resume=UUID configuration."
    fi

    local grub_tmp
    grub_tmp="$(mktemp)"
    cat <<EOF > "$grub_tmp"
# GRUB configuration optimized for Lenovo ThinkPad 13 2nd Gen (i5-7200U / HD 620 1920x1080 / Intel NVMe)
GRUB_DEFAULT=0
GRUB_TIMEOUT=2
GRUB_TIMEOUT_STYLE=menu
GRUB_DISTRIBUTOR=\`( . /etc/os-release && echo \${NAME} )\`
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash i915.enable_fbc=1 i915.fastboot=1 nmi_watchdog=0 nvme_core.default_ps_max_latency_us=5500 zswap.enabled=0${resume_cmdline}"
GRUB_CMDLINE_LINUX=""
GRUB_GFXMODE=1920x1080x32,1920x1080,auto
GRUB_GFXPAYLOAD_LINUX=keep
EOF

    if [ -f /etc/default/grub ] && ! cmp -s "$grub_tmp" /etc/default/grub; then
        cp -a /etc/default/grub "/etc/default/grub.bak.$(date +%Y%m%d%H%M%S)"
    fi
    install -m 644 "$grub_tmp" /etc/default/grub
    rm -f "$grub_tmp"
    log_ok "Base ThinkPad /etc/default/grub configured (1920x1080, GRUB_GFXPAYLOAD_LINUX=keep)."
}

# ------------------------------------------------------------------------------
# PART 2: Fedora-Style Debian BGRT Plymouth Theme + Seamless Silent Boot
# ------------------------------------------------------------------------------
check_plymouth_deps() {
    local missing=()
    for cmd in plymouth update-initramfs; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done

    if [ ! -x /usr/sbin/plymouth-set-default-theme ]; then
        missing+=("plymouth-set-default-theme")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing required Plymouth utilities: ${missing[*]}"
        log_error "Install them via: sudo apt install plymouth plymouth-themes"
        exit 1
    fi

    if [ ! -d "$BGRT_THEME_DIR" ] || [ ! -d "$SPINNER_THEME_DIR" ]; then
        log_error "Plymouth 'bgrt' or 'spinner' theme directory is missing."
        log_error "Install themes via: sudo apt install plymouth-themes"
        exit 1
    fi
}

configure_silent_boot() {
    mkdir -p "$STATE_DIR" "$BACKUP_DIR"

    log_step "[BGRT] Configuring seamless, flicker-free silent boot transition"

    # 1. Hide GRUB menu and suppress cursor / verbose messages via drop-in
    mkdir -p /etc/default/grub.d
    log_info "Creating GRUB silent drop-in (${GRUB_SILENT_CFG})..."
    cat <<'EOF' > "$GRUB_SILENT_CFG"
# Generated by thinkpad-debian-suite (debian-bgrt-plymouth)
# Hide GRUB menu for a seamless UEFI-to-Plymouth transition
GRUB_TIMEOUT=0
GRUB_TIMEOUT_STYLE=hidden

# Ensure quiet/splash and silent boot kernel parameters are present
for _opt in quiet splash vt.global_cursor_default=0 loglevel=3 systemd.show_status=auto rd.udev.log_level=3; do
    case " $GRUB_CMDLINE_LINUX_DEFAULT " in
        *" $_opt "*) ;;
        *) GRUB_CMDLINE_LINUX_DEFAULT="${GRUB_CMDLINE_LINUX_DEFAULT:+${GRUB_CMDLINE_LINUX_DEFAULT} }$_opt" ;;
    esac
done
EOF

    # 2. Silence "Loading Linux..." and "Loading initial ramdisk..." in /etc/grub.d/10_linux
    if [ -f "$GRUB_10_LINUX" ]; then
        if grep -q '^quiet_boot="0"' "$GRUB_10_LINUX"; then
            if [ ! -f "${BACKUP_DIR}/10_linux.bak" ]; then
                cp -p "$GRUB_10_LINUX" "${BACKUP_DIR}/10_linux.bak"
            fi
            log_info "Silencing 'Loading Linux...' text strings in ${GRUB_10_LINUX}..."
            sed -i 's/^quiet_boot="0"/quiet_boot="1"/' "$GRUB_10_LINUX"
        fi
    fi

    # 3. Configure Early KMS in /etc/initramfs-tools/modules (prevents mode-switch flash)
    local gpu_driver=""
    gpu_driver="$(detect_gpu_driver)"
    if [ -n "$gpu_driver" ] && [ -f "$INITRAMFS_MODULES" ]; then
        case "$gpu_driver" in
            i915|xe|amdgpu|radeon|nouveau)
                if ! grep -q "^[[:space:]]*${gpu_driver}[[:space:]]*$" "$INITRAMFS_MODULES"; then
                    if [ ! -f "${BACKUP_DIR}/modules.bak" ]; then
                        cp -p "$INITRAMFS_MODULES" "${BACKUP_DIR}/modules.bak"
                    fi
                    log_info "Adding GPU driver '${gpu_driver}' to Early KMS (${INITRAMFS_MODULES})..."
                    echo "$gpu_driver" >> "$INITRAMFS_MODULES"
                else
                    log_info "Early KMS already includes '${gpu_driver}' in ${INITRAMFS_MODULES}."
                fi
                ;;
        esac
    fi
}

revert_silent_boot() {
    log_step "[BGRT] Reverting silent boot settings"

    if [ -f "$GRUB_SILENT_CFG" ]; then
        log_info "Removing ${GRUB_SILENT_CFG}..."
        rm -f "$GRUB_SILENT_CFG"
    fi

    if [ -f "${BACKUP_DIR}/10_linux.bak" ]; then
        log_info "Restoring original ${GRUB_10_LINUX}..."
        cp -p "${BACKUP_DIR}/10_linux.bak" "$GRUB_10_LINUX"
        rm -f "${BACKUP_DIR}/10_linux.bak"
    fi

    if [ -f "${BACKUP_DIR}/modules.bak" ]; then
        log_info "Restoring original ${INITRAMFS_MODULES}..."
        cp -p "${BACKUP_DIR}/modules.bak" "$INITRAMFS_MODULES"
        rm -f "${BACKUP_DIR}/modules.bak"
    fi
}

apply_bgrt_plymouth() {
    local variant="${1:-text}"
    local rebuild_boot="${2:-1}"

    check_plymouth_deps

    local watermark_file=""
    local variant_desc=""
    local tmp_watermark=""

    case "$variant" in
        badge|icon)
            variant="badge"
            watermark_file="${ASSETS_DIR}/watermark-badge.png"
            variant_desc="Circular Papirus Debian badge alone (64x64)"
            ;;
        swirl)
            variant="swirl"
            watermark_file="${ASSETS_DIR}/watermark-swirl.png"
            variant_desc="Standalone Debian swirl alone in Papirus #f9548f"
            ;;
        text|fedora|*)
            variant="text"
            watermark_file="${ASSETS_DIR}/watermark-badge-with-text.png"
            variant_desc="Fedora style: Papirus badge + white 'debian' text"
            ;;
    esac

    if [ ! -f "$watermark_file" ]; then
        log_info "External asset not found at ${watermark_file}; extracting embedded '${variant}' PNG asset..."
        tmp_watermark="$(mktemp --suffix=.png)"
        extract_embedded_watermark "$variant" "$tmp_watermark"
        watermark_file="$tmp_watermark"
    fi

    log_step "[BGRT] Applying Plymouth BGRT Theme with Papirus Debian Logo (${variant_desc})"

    # Step 1: Backup current state if not already recorded
    mkdir -p "$STATE_DIR" "$BACKUP_DIR"

    if [ ! -f "$STATE_FILE" ]; then
        local current_theme=""
        current_theme="$(/usr/sbin/plymouth-set-default-theme 2>/dev/null || echo "")"
        if [ -z "$current_theme" ] || [ "$current_theme" = "bgrt" ]; then
            current_theme="ceratopsian"
        fi

        log_info "Saving original theme state (${current_theme}) to ${STATE_FILE}..."
        cat <<EOF > "$STATE_FILE"
ORIGINAL_THEME="${current_theme}"
APPLIED_VARIANT="${variant}"
APPLIED_DATE="$(date --iso-8601=seconds)"
HAD_WATERMARK_SPINNER=0
HAD_WATERMARK_BGRT=0
EOF

        if [ -f "${SPINNER_THEME_DIR}/watermark.png" ]; then
            cp -p "${SPINNER_THEME_DIR}/watermark.png" "${BACKUP_DIR}/spinner-watermark.png"
            sed -i 's/HAD_WATERMARK_SPINNER=0/HAD_WATERMARK_SPINNER=1/' "$STATE_FILE"
        fi

        if [ -f "${BGRT_THEME_DIR}/watermark.png" ]; then
            cp -p "${BGRT_THEME_DIR}/watermark.png" "${BACKUP_DIR}/bgrt-watermark.png"
            sed -i 's/HAD_WATERMARK_BGRT=0/HAD_WATERMARK_BGRT=1/' "$STATE_FILE"
        fi
    else
        log_info "Existing backup state found; updating applied variant to '${variant}'..."
        sed -i "s/^APPLIED_VARIANT=.*/APPLIED_VARIANT=\"${variant}\"/" "$STATE_FILE"
        sed -i "s/^APPLIED_DATE=.*/APPLIED_DATE=\"$(date --iso-8601=seconds)\"/" "$STATE_FILE"
    fi

    # Step 2: Install watermark PNG to both spinner and bgrt themes
    log_info "Installing watermark image to Plymouth themes..."
    install -m 644 "$watermark_file" "${SPINNER_THEME_DIR}/watermark.png"
    install -m 644 "$watermark_file" "${BGRT_THEME_DIR}/watermark.png"
    if [ -n "$tmp_watermark" ]; then
        rm -f "$tmp_watermark"
    fi

    # Step 3: Set default theme to bgrt
    log_info "Setting default Plymouth theme to 'bgrt'..."
    /usr/sbin/plymouth-set-default-theme bgrt

    # Step 4: Configure silent & flicker-free boot
    configure_silent_boot

    # Step 5: Rebuild GRUB & initramfs if requested
    if [ "$rebuild_boot" -eq 1 ]; then
        rebuild_boot_images
    fi

    log_ok "Fedora-style BGRT Plymouth theme (${variant}) and silent boot configured."
}

revert_bgrt_plymouth() {
    check_plymouth_deps
    log_step "[BGRT] Reverting Plymouth BGRT theme and restoring original Debian configuration"

    local target_theme="ceratopsian"
    local had_spinner_wm=0
    local had_bgrt_wm=0

    if [ -f "$STATE_FILE" ]; then
        # shellcheck disable=SC1090
        source "$STATE_FILE"
        target_theme="${ORIGINAL_THEME:-ceratopsian}"
        had_spinner_wm="${HAD_WATERMARK_SPINNER:-0}"
        had_bgrt_wm="${HAD_WATERMARK_BGRT:-0}"
        log_info "Restoring previous theme: ${BOLD}${target_theme}${RESET}..."
    else
        log_warn "No state file found at ${STATE_FILE}. Falling back to Debian default '${target_theme}'."
    fi

    if [ "$had_spinner_wm" -eq 1 ] && [ -f "${BACKUP_DIR}/spinner-watermark.png" ]; then
        log_info "Restoring original spinner watermark..."
        install -m 644 "${BACKUP_DIR}/spinner-watermark.png" "${SPINNER_THEME_DIR}/watermark.png"
    elif [ -f "${SPINNER_THEME_DIR}/watermark.png" ]; then
        log_info "Removing spinner watermark..."
        rm -f "${SPINNER_THEME_DIR}/watermark.png"
    fi

    if [ "$had_bgrt_wm" -eq 1 ] && [ -f "${BACKUP_DIR}/bgrt-watermark.png" ]; then
        log_info "Restoring original bgrt watermark..."
        install -m 644 "${BACKUP_DIR}/bgrt-watermark.png" "${BGRT_THEME_DIR}/watermark.png"
    elif [ -f "${BGRT_THEME_DIR}/watermark.png" ]; then
        log_info "Removing bgrt watermark..."
        rm -f "${BGRT_THEME_DIR}/watermark.png"
    fi

    log_info "Setting Plymouth default theme back to '${target_theme}'..."
    /usr/sbin/plymouth-set-default-theme "$target_theme"

    revert_silent_boot
    rebuild_boot_images

    if [ -d "$STATE_DIR" ]; then
        rm -rf "$STATE_DIR"
        log_info "Removed state and backup directory (${STATE_DIR})."
    fi

    log_ok "Successfully reverted! System restored to '${target_theme}' theme."
}

rebuild_boot_images() {
    log_step "Rebuilding GRUB configuration and initramfs for all installed kernels"
    if [ -x /usr/sbin/update-grub ]; then
        log_info "Running update-grub..."
        /usr/sbin/update-grub >/dev/null 2>&1 || /usr/sbin/update-grub
    fi
    if command -v update-initramfs >/dev/null 2>&1; then
        log_info "Running update-initramfs -u -k all (this may take a few moments)..."
        update-initramfs -u -k all
    fi
    log_ok "Bootloader (GRUB) and initramfs updated."
}

# ------------------------------------------------------------------------------
# PART 3: Realtek ALC298 Microphone & Bluetooth A2DP Audio Optimizer (User)
# ------------------------------------------------------------------------------
apply_audio_settings_as_current_user() {
    log_info "[Audio 1/3] Calibrating internal microphone gain (ALC298 / ${AUDIO_CARD_NAME})..."
    if command -v amixer >/dev/null 2>&1; then
        amixer -q -c "$AUDIO_CARD_NAME" set 'Internal Mic Boost' "$AUDIO_MIC_BOOST" 2>/dev/null || true
        amixer -q -c "$AUDIO_CARD_NAME" set 'Capture' "$AUDIO_CAPTURE_LEVEL" cap 2>/dev/null || true
    else
        log_warn "amixer not found; skipping ALSA hardware gain calibration."
    fi

    log_info "[Audio 2/3] Setting internal mic as default PipeWire input..."
    if command -v pw-dump >/dev/null 2>&1 && command -v wpctl >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
        local src_id=""
        src_id="$(pw-dump 2>/dev/null | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for o in data:
    p = (o.get('info') or {}).get('props') or {}
    if p.get('node.name') == '${AUDIO_INTERNAL_MIC_NODE}':
        print(o['id'])
        break
" 2>/dev/null || true)"
        if [ -n "$src_id" ]; then
            wpctl set-default "$src_id" || true
            wpctl set-volume "$src_id" "$AUDIO_SOURCE_VOLUME" || true
            log_ok "Default input set to internal mic (id=${src_id}, volume=${AUDIO_SOURCE_VOLUME})."
        else
            log_warn "Internal mic PipeWire node (${AUDIO_INTERNAL_MIC_NODE}) not found or PipeWire inactive; skipping live set."
        fi
    else
        log_warn "pw-dump/wpctl/python3 unavailable; skipping live PipeWire input adjustment."
    fi

    # Re-apply analog gain last: PipeWire's ACP mixer may remap boost on volume change
    if command -v amixer >/dev/null 2>&1; then
        amixer -q -c "$AUDIO_CARD_NAME" set 'Internal Mic Boost' "$AUDIO_MIC_BOOST" 2>/dev/null || true
    fi

    log_info "[Audio 3/3] Switching Bluetooth headsets to A2DP high-fidelity playback..."
    if command -v pw-dump >/dev/null 2>&1 && command -v wpctl >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
        pw-dump 2>/dev/null | python3 -c "
import json, sys, subprocess
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for o in data:
    info = o.get('info') or {}
    props = info.get('props') or {}
    if props.get('device.api') != 'bluez5':
        continue
    profiles = (info.get('params') or {}).get('EnumProfile', [])
    names = {p.get('name'): p.get('index') for p in profiles}
    for pref in ('a2dp-sink-sbc_xq', 'a2dp-sink'):
        if pref in names:
            subprocess.run(['wpctl', 'set-profile', str(o['id']), str(names[pref])], check=False)
            print(f\"  {props.get('device.description')}: {pref}\")
            break
" 2>/dev/null || true
    fi
}

install_audio_user_service_for_home() {
    local user_home="$1"
    local dest="${user_home}/.local/bin/thinkpad-audio-optimize"
    local unit_dir="${user_home}/.config/systemd/user"
    local unit_file="${unit_dir}/thinkpad-audio-optimize.service"

    mkdir -p "${user_home}/.local/bin" "$unit_dir"

    cat <<EOF > "$dest"
#!/usr/bin/env bash
# Auto-generated by thinkpad-debian-suite.sh
# Calibrates Realtek ALC298 internal mic gain & Bluetooth A2DP profile at login.
set -euo pipefail

CARD_NAME="${AUDIO_CARD_NAME}"
INTERNAL_MIC_NODE="${AUDIO_INTERNAL_MIC_NODE}"
MIC_BOOST=${AUDIO_MIC_BOOST}
CAPTURE_LEVEL="${AUDIO_CAPTURE_LEVEL}"
SOURCE_VOLUME="${AUDIO_SOURCE_VOLUME}"

amixer -q -c "\$CARD_NAME" set 'Internal Mic Boost' "\$MIC_BOOST" 2>/dev/null || true
amixer -q -c "\$CARD_NAME" set 'Capture' "\$CAPTURE_LEVEL" cap 2>/dev/null || true

src_id="\$(pw-dump 2>/dev/null | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for o in data:
    p = (o.get('info') or {}).get('props') or {}
    if p.get('node.name') == '\$INTERNAL_MIC_NODE':
        print(o['id'])
        break
" 2>/dev/null || true)"

if [ -n "\${src_id:-}" ]; then
    wpctl set-default "\$src_id" || true
    wpctl set-volume "\$src_id" "\$SOURCE_VOLUME" || true
fi

# Re-apply analog boost after PipeWire volume adjustment
amixer -q -c "\$CARD_NAME" set 'Internal Mic Boost' "\$MIC_BOOST" 2>/dev/null || true

pw-dump 2>/dev/null | python3 -c "
import json, sys, subprocess
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for o in data:
    info = o.get('info') or {}
    props = info.get('props') or {}
    if props.get('device.api') != 'bluez5':
        continue
    profiles = (info.get('params') or {}).get('EnumProfile', [])
    names = {p.get('name'): p.get('index') for p in profiles}
    for pref in ('a2dp-sink-sbc_xq', 'a2dp-sink'):
        if pref in names:
            subprocess.run(['wpctl', 'set-profile', str(o['id']), str(names[pref])], check=False)
            break
" 2>/dev/null || true
EOF
    chmod 755 "$dest"

    cat <<EOF > "$unit_file"
[Unit]
Description=ThinkPad 13 microphone gain & Bluetooth audio profile fix
After=pipewire.service wireplumber.service
Wants=wireplumber.service

[Service]
Type=oneshot
ExecStartPre=/bin/sleep 5
ExecStart=${dest}

[Install]
WantedBy=default.target
EOF
}

run_audio_optimizer() {
    local apply_only="${1:-0}"
    log_step "[Audio] Optimizing Realtek ALC298 Microphone Gain & Bluetooth A2DP Audio"

    if [ "$(id -u)" -ne 0 ]; then
        apply_audio_settings_as_current_user
        if [ "$apply_only" -eq 0 ]; then
            install_audio_user_service_for_home "$HOME"
            if systemctl --user daemon-reload 2>/dev/null && systemctl --user enable thinkpad-audio-optimize.service 2>/dev/null; then
                log_ok "User login service installed & enabled: thinkpad-audio-optimize.service"
            else
                mkdir -p "${HOME}/.config/systemd/user/default.target.wants"
                ln -sf ../thinkpad-audio-optimize.service "${HOME}/.config/systemd/user/default.target.wants/thinkpad-audio-optimize.service"
                log_ok "User login service installed & enabled via symlink: thinkpad-audio-optimize.service"
            fi
            log_info "Tip: EasyEffects input filters apply to whichever mic is selected; prefer mSBC ('headset-head-unit') over CVSD for BT headset mics."
        fi
        return 0
    fi

    # Running as root: locate the target desktop user and drop privileges cleanly
    local user
    user="$(detect_target_user)"
    if [ -z "$user" ] || [ "$user" = "root" ] || ! id "$user" >/dev/null 2>&1; then
        log_warn "Could not detect a non-root desktop user for PipeWire audio optimization."
        log_warn "Run './thinkpad-debian-suite.sh audio' as your normal user (without sudo) to configure audio."
        return 0
    fi

    local uid gid user_home runtime_dir dbus_addr
    uid="$(id -u "$user")"
    gid="$(id -g "$user")"
    user_home="$(getent passwd "$user" | cut -d: -f6)"
    runtime_dir="/run/user/${uid}"
    dbus_addr="unix:path=${runtime_dir}/bus"

    log_info "Running user-session audio optimization for desktop user '${user}' (uid=${uid})..."

    if [ "$apply_only" -eq 0 ]; then
        install_audio_user_service_for_home "$user_home"
        chown -R "${uid}:${gid}" "${user_home}/.local/bin/thinkpad-audio-optimize" "${user_home}/.config/systemd/user/thinkpad-audio-optimize.service"
    fi

    if [ -S "${runtime_dir}/bus" ]; then
        runuser -u "$user" -- env \
            HOME="$user_home" \
            XDG_RUNTIME_DIR="$runtime_dir" \
            DBUS_SESSION_BUS_ADDRESS="$dbus_addr" \
            bash "$SCRIPT_PATH" audio --apply || true

        if [ "$apply_only" -eq 0 ]; then
            if runuser -u "$user" -- env \
                HOME="$user_home" \
                XDG_RUNTIME_DIR="$runtime_dir" \
                DBUS_SESSION_BUS_ADDRESS="$dbus_addr" \
                systemctl --user daemon-reload && \
               runuser -u "$user" -- env \
                HOME="$user_home" \
                XDG_RUNTIME_DIR="$runtime_dir" \
                DBUS_SESSION_BUS_ADDRESS="$dbus_addr" \
                systemctl --user enable thinkpad-audio-optimize.service; then
                log_ok "User login service installed & enabled for '${user}': thinkpad-audio-optimize.service"
            else
                mkdir -p "${user_home}/.config/systemd/user/default.target.wants"
                ln -sf ../thinkpad-audio-optimize.service "${user_home}/.config/systemd/user/default.target.wants/thinkpad-audio-optimize.service"
                chown -h "${uid}:${gid}" "${user_home}/.config/systemd/user/default.target.wants/thinkpad-audio-optimize.service"
                log_ok "User login service enabled via symlink for '${user}': thinkpad-audio-optimize.service"
            fi
        fi
    else
        log_warn "No active user D-Bus session at ${runtime_dir}/bus; applying ALSA calibration & enabling user login service for next login."
        if command -v amixer >/dev/null 2>&1; then
            amixer -q -c "$AUDIO_CARD_NAME" set 'Internal Mic Boost' "$AUDIO_MIC_BOOST" 2>/dev/null || true
            amixer -q -c "$AUDIO_CARD_NAME" set 'Capture' "$AUDIO_CAPTURE_LEVEL" cap 2>/dev/null || true
        fi
        if [ "$apply_only" -eq 0 ]; then
            mkdir -p "${user_home}/.config/systemd/user/default.target.wants"
            ln -sf ../thinkpad-audio-optimize.service "${user_home}/.config/systemd/user/default.target.wants/thinkpad-audio-optimize.service"
            chown -R "${uid}:${gid}" "${user_home}/.config/systemd/user"
            log_ok "User login service enabled via symlink for '${user}': thinkpad-audio-optimize.service"
        fi
    fi
}

# ------------------------------------------------------------------------------
# Unified Status & Health Verification
# ------------------------------------------------------------------------------
show_status() {
    echo -e "${BOLD}==================================================================${RESET}"
    echo -e "${BOLD} Lenovo ThinkPad Debian Super Suite — System & Boot Status${RESET}"
    echo -e "${BOLD}==================================================================${RESET}"

    echo -e "\n${CYAN}--- Swap, ZRAM & Zswap ---${RESET}"
    swapon --show 2>/dev/null || echo "  (no active swap)"
    if [ -r /sys/module/zswap/parameters/enabled ]; then
        echo -e "  zswap enabled:         $(cat /sys/module/zswap/parameters/enabled)"
    fi

    echo -e "\n${CYAN}--- Transparent Hugepages (THP) ---${RESET}"
    [ -r /sys/kernel/mm/transparent_hugepage/enabled ] && echo "  enabled:               $(cat /sys/kernel/mm/transparent_hugepage/enabled)"
    [ -r /sys/kernel/mm/transparent_hugepage/defrag ]  && echo "  defrag:                $(cat /sys/kernel/mm/transparent_hugepage/defrag)"

    echo -e "\n${CYAN}--- Active Sysctl Values ---${RESET}"
    sysctl kernel.nmi_watchdog vm.swappiness vm.watermark_boost_factor vm.watermark_scale_factor \
        vm.vfs_cache_pressure vm.dirty_writeback_centisecs \
        net.ipv4.tcp_congestion_control net.core.default_qdisc net.ipv4.tcp_fastopen 2>/dev/null | sed 's/^/  /' || true

    echo -e "\n${CYAN}--- Battery Charge Thresholds ---${RESET}"
    local found_bat=0
    for bat in /sys/class/power_supply/BAT*; do
        if [ -r "$bat/charge_control_end_threshold" ]; then
            found_bat=1
            local s="?" e="?"
            [ -r "$bat/charge_control_start_threshold" ] && s="$(cat "$bat/charge_control_start_threshold")"
            e="$(cat "$bat/charge_control_end_threshold")"
            echo "  $(basename "$bat"):                  start=${s}% / end=${e}%"
        fi
    done
    [ "$found_bat" -eq 0 ] && echo "  (no ThinkPad battery thresholds exposed)"

    echo -e "\n${CYAN}--- NVMe SMART Health Summary ---${RESET}"
    if [ "$(id -u)" -eq 0 ] && command -v nvme >/dev/null 2>&1 && [ -e /dev/nvme0n1 ]; then
        (nvme smart-log /dev/nvme0n1 2>/dev/null || true) | head -n 15 | sed 's/^/  /'
    elif [ -e /dev/nvme0n1 ]; then
        echo "  (run with sudo to query nvme smart-log /dev/nvme0n1)"
    else
        echo "  (no /dev/nvme0n1 device detected)"
    fi

    echo -e "\n${CYAN}--- Audio Optimizer (ALC298 + PipeWire) ---${RESET}"
    local target_user user_home
    target_user="$(detect_target_user)"
    user_home=""
    if [ -n "$target_user" ]; then
        user_home="$(getent passwd "$target_user" 2>/dev/null | cut -d: -f6 || true)"
    fi
    if [ -n "$user_home" ] && [ -f "${user_home}/.config/systemd/user/thinkpad-audio-optimize.service" ]; then
        echo -e "  User Login Service:    ${GREEN}Installed${RESET} (${user_home}/.config/systemd/user/thinkpad-audio-optimize.service)"
    else
        echo -e "  User Login Service:    ${YELLOW}Not installed${RESET}"
    fi
    if command -v amixer >/dev/null 2>&1; then
        local mic_boost
        mic_boost="$(amixer -c "$AUDIO_CARD_NAME" sget 'Internal Mic Boost' 2>/dev/null | grep -m1 -oE '\[[0-9]+%\]|\[[0-9]+\.[0-9]+dB\]' | tr '\n' ' ' || true)"
        [ -n "$mic_boost" ] && echo "  Internal Mic Boost:    ${mic_boost}"
    fi

    echo -e "\n${CYAN}--- Plymouth Debian BGRT & Silent Boot Status ---${RESET}"
    local cur_theme="Unknown"
    if [ -x /usr/sbin/plymouth-set-default-theme ]; then
        cur_theme="$(/usr/sbin/plymouth-set-default-theme 2>/dev/null || echo "Unknown")"
    fi
    echo -e "  Current Active Theme:  ${BOLD}${cur_theme}${RESET}"

    if [ -f "$STATE_FILE" ]; then
        # shellcheck disable=SC1090
        source "$STATE_FILE"
        echo -e "  Theme State:           ${GREEN}Managed by BGRT suite${RESET}"
        echo -e "  Original Theme:        ${BOLD}${ORIGINAL_THEME:-unknown}${RESET}"
        echo -e "  Applied Variant:       ${BOLD}${APPLIED_VARIANT:-unknown}${RESET}"
        echo -e "  Applied Date:          ${APPLIED_DATE:-unknown}"
    else
        echo -e "  Theme State:           ${YELLOW}Stock / Unmanaged${RESET}"
    fi

    echo -n "  Spinner Watermark:     "
    if [ -f "${SPINNER_THEME_DIR}/watermark.png" ]; then
        echo -e "${GREEN}Present${RESET} (${SPINNER_THEME_DIR}/watermark.png)"
    else
        echo -e "${YELLOW}None${RESET}"
    fi

    echo -n "  BGRT Watermark:        "
    if [ -f "${BGRT_THEME_DIR}/watermark.png" ]; then
        echo -e "${GREEN}Present${RESET} (${BGRT_THEME_DIR}/watermark.png)"
    else
        echo -e "${YELLOW}None${RESET}"
    fi

    echo -n "  GRUB Silent Drop-in:   "
    if [ -f "$GRUB_SILENT_CFG" ]; then
        echo -e "${GREEN}Active${RESET} (${GRUB_SILENT_CFG})"
    else
        echo -e "${YELLOW}Not installed${RESET}"
    fi

    echo -n "  GRUB Loader Text:      "
    if grep -q '^quiet_boot="1"' "$GRUB_10_LINUX" 2>/dev/null; then
        echo -e "${GREEN}Silenced${RESET} (No 'Loading Linux...' text)"
    else
        echo -e "${YELLOW}Visible${RESET} (Prints 'Loading Linux...')"
    fi

    echo -n "  Early KMS (GPU):       "
    local gpu_driver
    gpu_driver="$(detect_gpu_driver)"
    if [ -n "$gpu_driver" ] && grep -q "^[[:space:]]*${gpu_driver}[[:space:]]*$" "$INITRAMFS_MODULES" 2>/dev/null; then
        echo -e "${GREEN}Enabled${RESET} (${gpu_driver} in ${INITRAMFS_MODULES})"
    else
        echo -e "${YELLOW}Not in Early KMS${RESET} (Detected: ${gpu_driver:-None})"
    fi

    echo -n "  UEFI BGRT OEM Support: "
    if [ -d /sys/firmware/acpi/bgrt ]; then
        local bgrt_status=0
        [ -r /sys/firmware/acpi/bgrt/status ] && bgrt_status="$(cat /sys/firmware/acpi/bgrt/status 2>/dev/null || echo 0)"
        if [ "$bgrt_status" = "1" ]; then
            echo -e "${GREEN}Active & Valid${RESET} (OEM logo retained during boot)"
        else
            echo -e "${YELLOW}Detected (status=${bgrt_status})${RESET}"
        fi
    else
        echo -e "${YELLOW}Not detected${RESET} (Legacy BIOS or non-BGRT UEFI)"
    fi
    echo ""
}

# ------------------------------------------------------------------------------
# Argument Parsing
# ------------------------------------------------------------------------------
ORIG_ARGS=("$@")
POSITIONAL=()

while [ $# -gt 0 ]; do
    case "$1" in
        --variant)
            if [ $# -lt 2 ]; then
                log_error "--variant requires an argument (text | badge | swirl)."
                exit 1
            fi
            BGRT_VARIANT="$2"
            shift 2
            ;;
        --no-bgrt)
            SKIP_BGRT=1
            shift
            ;;
        --no-audio)
            SKIP_AUDIO=1
            shift
            ;;
        --apply)
            AUDIO_APPLY_ONLY=1
            shift
            ;;
        --user)
            if [ $# -lt 2 ]; then
                log_error "--user requires a username argument."
                exit 1
            fi
            TARGET_USER="$2"
            shift 2
            ;;
        -h|--help|help)
            show_help
            exit 0
            ;;
        -*)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done

if [ ${#POSITIONAL[@]} -gt 0 ]; then
    ACTION="${POSITIONAL[0]}"
fi
if [ ${#POSITIONAL[@]} -gt 1 ]; then
    BGRT_VARIANT="${POSITIONAL[1]}"
fi

# ------------------------------------------------------------------------------
# Main Dispatcher
# ------------------------------------------------------------------------------
case "$ACTION" in
    all|full|install)
        ensure_root
        echo -e "${BOLD}==================================================================${RESET}"
        echo -e "${BOLD} Lenovo ThinkPad Debian Super Optimization Suite${RESET}"
        echo -e "${BOLD}==================================================================${RESET}"

        install_system_packages
        optimize_nvme_ssd
        optimize_power_zram_battery
        optimize_wifi_network

        if [ "$SKIP_BGRT" -eq 0 ]; then
            configure_thinkpad_grub_and_boot 0
            apply_bgrt_plymouth "$BGRT_VARIANT" 0
        else
            configure_thinkpad_grub_and_boot 1
        fi

        rebuild_boot_images

        if [ "$SKIP_AUDIO" -eq 0 ]; then
            run_audio_optimizer 0
        fi

        echo ""
        show_status
        echo -e "${GREEN}${BOLD}==================================================================${RESET}"
        echo -e "${GREEN}${BOLD} All ThinkPad Optimization, Audio & BGRT Plymouth Tasks Complete!${RESET}"
        echo -e "${GREEN}${BOLD} Reboot to enjoy your optimized, flicker-free Debian system.${RESET}"
        echo -e "${GREEN}${BOLD}==================================================================${RESET}"
        ;;

    system|thinkpad)
        ensure_root
        install_system_packages
        optimize_nvme_ssd
        optimize_power_zram_battery
        optimize_wifi_network
        configure_thinkpad_grub_and_boot 1
        rebuild_boot_images
        echo ""
        show_status
        log_ok "System optimization completed successfully!"
        ;;

    audio|mic)
        run_audio_optimizer "$AUDIO_APPLY_ONLY"
        log_ok "Audio optimization completed!"
        ;;

    bgrt|plymouth)
        ensure_root
        apply_bgrt_plymouth "$BGRT_VARIANT" 1
        echo ""
        echo -e "To revert at any time, run: ${BOLD}sudo $0 revert-bgrt${RESET}"
        ;;

    silent-boot|silent-grub|flicker-free)
        ensure_root
        configure_silent_boot
        rebuild_boot_images
        log_ok "Silent & flicker-free boot configured successfully!"
        ;;

    revert-bgrt|revert|uninstall-bgrt)
        ensure_root
        revert_bgrt_plymouth
        ;;

    status)
        show_status
        ;;

    *)
        log_error "Unknown command: ${ACTION}"
        show_help
        exit 1
        ;;
esac
