#!/bin/bash
# LightyearOS image build script

set -ouex pipefail

# ── COPRs ──────────────────────────────────────────────────────────────────────

dnf5 -y copr enable yalter/niri-git
dnf5 -y copr enable avengemedia/danklinux
dnf5 -y copr enable avengemedia/dms
dnf5 -y copr enable bieszczaders/kernel-cachyos-addons

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

# ── Hardware: stuff ─────────────────────────────────────────────────

dnf5 install -y \
    coolercontrol \
    liquidctl 

# ── Sysadmin tools ─────────────────────────────────────────────────────────────

dnf5 install -y \
    tmux

# ── Disable COPRs ──────────────────────────────────────────────────────────────

dnf5 -y copr disable yalter/niri-git
dnf5 -y copr disable avengemedia/danklinux
dnf5 -y copr disable avengemedia/dms
dnf5 -y copr disable bieszczaders/kernel-cachyos-addons

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

# ── Greeter wallpaper symlink ──────────────────────────────────────────────────

mkdir -p /etc/lightyearos
ln -sf /usr/share/backgrounds/lightyearos/wallpaper-01.jpg \
    /etc/lightyearos/greeter-background