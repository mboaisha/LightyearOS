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

# ── Hardware: it87 kmod ────────────────────────────────────────────────────────
# Gigabyte B850 needs it87 for fan header access via hwmon
# it87-extras is an akmod — source gets compiled against current kernel headers
# bazzite-dx-nvidia ships kernel-devel so headers are available

dnf5 -y copr enable grandpares/it87-extras
dnf5 install -y it87-extras
akmods --force
dnf5 -y copr disable grandpares/it87-extras

# Verify the kmod actually compiled
KVER=$(rpm -q kernel --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' | tail -1)
if ! ls /usr/lib/modules/${KVER}/extra/it87.ko* 1>/dev/null 2>&1; then
    echo "ERROR: it87 kmod failed to build for kernel ${KVER}" >&2
    exit 1
fi

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

systemctl enable greetd.service
ln -sf /usr/lib/systemd/system/greetd.service \
    /etc/systemd/system/display-manager.service
systemctl disable gdm.service 2>/dev/null || true
systemctl enable coolercontrold.service
systemctl enable podman.socket

# ── Kernel module loading ──────────────────────────────────────────────────────
# modules-load.d is the standard mechanism — no custom service needed

mkdir -p /usr/lib/modules-load.d
echo "it87" > /usr/lib/modules-load.d/it87.conf

# ── Kernel arguments ──────────────────────────────────────────────────────────
# acpi_enforce_resources=lax required on Gigabyte B850 for it87 register access

mkdir -p /usr/lib/kernel/cmdline.d
echo "acpi_enforce_resources=lax" > /usr/lib/kernel/cmdline.d/it87.conf

# ── Greeter wallpaper symlink ──────────────────────────────────────────────────

mkdir -p /etc/lightyearos
ln -sf /usr/share/backgrounds/lightyearos/wallpaper-01.jpg \
    /etc/lightyearos/greeter-background