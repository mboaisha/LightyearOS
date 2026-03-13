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

# ── Hardware-specific ─────────────────────────────────────────────────

# Trying to follow how Bazzite installs CoolerControl and Liquidctl

# liquidctl is in Fedora repos
dnf5 install -y \
    liquidctl
# Enable Terra and install CoolerControl
sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/terra.repo
dnf5 install -y coolercontrol
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/terra.repo

# it87 kmod for Gigabyte B850 fan headers
# it87-extras is an akmod — installs source, akmods --force compiles it
# kernel-devel is available because we're on bazzite-dx-nvidia
dnf5 -y copr enable grandpares/it87-extras
dnf5 install -y it87-extras
akmods --force
dnf5 -y copr disable grandpares/it87-extras

# ── Sysadmin tools ─────────────────────────────────────────────────────────────
# Here, I will throw more tools in after a successful build.
# Once I figure out how to pre-install flatpaks here
# or in the containerfile

dnf5 install -y \
    tmux

# ── Disable COPRs ──────────────────────────────────────────────────────────────

dnf5 -y copr disable yalter/niri-git
dnf5 -y copr disable avengemedia/danklinux
dnf5 -y copr disable avengemedia/dms

# ── Cleanup ────────────────────────────────────────────────────────────────────

dnf5 clean all

# ── Systemd services ───────────────────────────────────────────────────────────

systemctl enable greetd.service
ln -sf /usr/lib/systemd/system/greetd.service \
    /etc/systemd/system/display-manager.service
systemctl disable gdm.service 2>/dev/null || true
systemctl enable coolercontrold.service
systemctl enable load-it87.service
systemctl enable podman.socket

# ── Kernel arguments ───────────────────────────────────────────────────────────

# Required on some boards for it87 to access fan control registers
# Gigabyte B850 falls into this category
# In build.sh

# As per https://copr.fedorainfracloud.org/coprs/grandpares/it87-extras/
# "Some motherboards may require karg acpi_enforce_resources=lax to load the driver."
# I suspect my motherboard requires it.

mkdir -p /usr/lib/kernel/cmdline.d
echo "acpi_enforce_resources=lax" > \
    /usr/lib/kernel/cmdline.d/it87.conf

# ── Greeter wallpaper symlink ──────────────────────────────────────────────────

mkdir -p /etc/lightyearos
ln -sf /usr/share/backgrounds/lightyearos/wallpaper-01.jpg \
    /etc/lightyearos/greeter-background