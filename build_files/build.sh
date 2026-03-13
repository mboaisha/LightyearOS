#!/bin/bash
# LightyearOS image build script

set -ouex pipefail

# ── COPRs ──────────────────────────────────────────────────────────────────────

dnf5 -y copr enable yalter/niri-git
dnf5 -y copr enable avengemedia/danklinux
dnf5 -y copr enable avengemedia/dms

# ── Niri + DMS desktop stack ───────────────────────────────────────────────────

dnf5 install -y \
    niri \
    xwayland-satellite \
    dms \
    dms-cli \
    dms-greeter \
    quickshell \
    matugen \
    cliphist \
    danksearch \
    dgop \
    foot \
    greetd \
    greetd-selinux \
    chezmoi

# ── Hardware: CoolerControl + liquidctl ────────────────────────────────────────
# liquidctl: CLI/lib for controlling liquid coolers, fans, LEDs (Fedora repos)
# coolercontrol: GUI daemon for fan curves and AIO (Terra repo, disabled in Bazzite)

dnf5 install -y liquidctl

sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/terra.repo
dnf5 install -y coolercontrol
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/terra.repo

# ── Hardware: it87 ─────────────────────────────────────────────────────────────
# Bazzite's kernel (6.17+) already includes the it87-extras patches in-tree.
# Verified: IT8790E, IT8628E, IT8772E, IT87952E chip IDs present in
# /usr/lib/modules/*/kernel/drivers/hwmon/it87.ko.xz
#
# All we need is:
#   1. Load the in-tree module at boot
#   2. Kernel arg for ACPI register access on Gigabyte boards

mkdir -p /usr/lib/modules-load.d
echo "it87" > /usr/lib/modules-load.d/it87.conf

mkdir -p /usr/lib/kernel/cmdline.d
echo "acpi_enforce_resources=lax" > /usr/lib/kernel/cmdline.d/it87.conf

# ── Sysadmin tools ─────────────────────────────────────────────────────────────

dnf5 install -y \
    tmux

# ── Disable COPRs ──────────────────────────────────────────────────────────────

dnf5 -y copr disable yalter/niri-git
dnf5 -y copr disable avengemedia/danklinux
dnf5 -y copr disable avengemedia/dms

# ── Cleanup ────────────────────────────────────────────────────────────────────

dnf5 clean all

# ── Systemd services ───────────────────────────────────────────────────────────

# ── Systemd services ───────────────────────────────────────────────────────────

rm -f /etc/systemd/system/display-manager.service
systemctl enable greetd.service
ln -sf /usr/lib/systemd/system/greetd.service \
    /etc/systemd/system/display-manager.service
systemctl disable gdm.service 2>/dev/null || true
systemctl enable coolercontrold.service
systemctl enable podman.socket

# ── Greeter wallpaper symlink ──────────────────────────────────────────────────

mkdir -p /etc/lightyearos
ln -sf /usr/share/backgrounds/lightyearos/wallpaper-01.jpg \
    /etc/lightyearos/greeter-background
