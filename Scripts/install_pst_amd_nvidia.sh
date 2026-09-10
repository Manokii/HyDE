#!/usr/bin/env bash
# AMD iGPU + NVIDIA dGPU hybrid laptops (e.g. ASUS ROG Flow X13 2023, G14, Zephyrus)
#
# Fixes the SDDM black-screen / GPU-not-loaded race at boot by:
#   1. Early-loading amdgpu + nvidia kernel modules in initramfs
#   2. Enabling NVIDIA DRM modeset + fbdev (required for Wayland/Hyprland)
#   3. Preserving dGPU VRAM across suspend (NVreg_PreserveVideoMemoryAllocations)
#   4. Enabling NVIDIA suspend/resume systemd services
#
# CAVEAT: If you use supergfxctl in "Integrated" or "Vfio" mode, this script
# detects that and skips the mkinitcpio MODULES change (forcing nvidia early-load
# would defeat the purpose of those modes). Re-run after switching to Hybrid.
#
# Skipped automatically if:
#   - System is not an AMD+NVIDIA hybrid (only one vendor present)
#   - No NVIDIA kernel module package is installed

scrDir=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1091
if ! source "${scrDir}/global_fn.sh"; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

# Hybrid detection: needs BOTH AMD and NVIDIA GPUs
if ! lspci | grep -qE '(VGA|3D|Display).*AMD/ATI' || ! lspci | grep -qE '(VGA|3D|Display).*NVIDIA'; then
    echo "[HYBRID] Not an AMD+NVIDIA hybrid system, skipping."
    exit 0
fi

# Detect any installed NVIDIA kernel module package
nvidia_pkg=""
for pkg in nvidia-dkms nvidia nvidia-open-dkms nvidia-open; do
    if pkg_installed "$pkg"; then
        nvidia_pkg="$pkg"
        break
    fi
done

if [ -z "$nvidia_pkg" ]; then
    echo "[HYBRID] No NVIDIA kernel module installed (try: nvidia-dkms or nvidia-open-dkms). Skipping."
    exit 0
fi

echo "[HYBRID] AMD iGPU + NVIDIA dGPU detected (driver: $nvidia_pkg)"

# supergfxctl awareness — if it's running and dGPU is unloaded, skip MODULES change
gfx_mode=""
if command -v supergfxctl &>/dev/null; then
    gfx_mode=$(supergfxctl -g 2>/dev/null || true)
    echo "[HYBRID] supergfxctl detected, current mode: ${gfx_mode:-unknown}"
fi

rebuild_initramfs=0

# 1. Early-load both GPU drivers in initramfs
if [ "$gfx_mode" = "Integrated" ] || [ "$gfx_mode" = "Vfio" ]; then
    echo "[HYBRID] supergfxctl is in $gfx_mode mode, skipping mkinitcpio MODULES change"
    echo "         (re-run this script after switching to Hybrid mode)"
elif grep -q '^MODULES=()' /etc/mkinitcpio.conf; then
    echo "[HYBRID] Adding amdgpu + nvidia* to mkinitcpio MODULES for early-load"
    sudo sed -i 's|^MODULES=()|MODULES=(amdgpu nvidia nvidia_modeset nvidia_uvm nvidia_drm)|' /etc/mkinitcpio.conf
    rebuild_initramfs=1
elif grep '^MODULES=' /etc/mkinitcpio.conf | grep -qv 'nvidia'; then
    echo "[HYBRID] WARNING: /etc/mkinitcpio.conf MODULES is non-default and missing nvidia entries."
    echo "[HYBRID] Please manually add: amdgpu nvidia nvidia_modeset nvidia_uvm nvidia_drm"
    grep '^MODULES=' /etc/mkinitcpio.conf
fi

# 2. NVIDIA modprobe options (Wayland DRM modeset, framebuffer, suspend VRAM preservation)
modprobe_conf=/etc/modprobe.d/nvidia.conf
if [ ! -f "$modprobe_conf" ]; then
    echo "[HYBRID] Writing $modprobe_conf"
    sudo tee "$modprobe_conf" > /dev/null <<'NVCONF'
options nvidia_drm modeset=1 fbdev=1
options nvidia NVreg_PreserveVideoMemoryAllocations=1
NVCONF
    rebuild_initramfs=1
else
    echo "[HYBRID] $modprobe_conf already present, leaving as-is"
fi

# 3. NVIDIA suspend/resume services (preserves dGPU state across sleep — common ROG Flow issue)
for svc in nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service; do
    if systemctl list-unit-files "$svc" &>/dev/null; then
        if ! systemctl is-enabled "$svc" &>/dev/null; then
            echo "[HYBRID] Enabling $svc"
            sudo systemctl enable "$svc"
        fi
    fi
done

# 4. Rebuild initramfs only if anything changed
if [ "$rebuild_initramfs" -eq 1 ]; then
    echo "[HYBRID] Rebuilding initramfs..."
    sudo mkinitcpio -P
else
    echo "[HYBRID] No changes needed."
fi

# 5. ASUS hardware hints (informational only — does not install)
if [ -r /sys/class/dmi/id/product_name ] && grep -qiE 'flow|zephyrus|tuf|rog' /sys/class/dmi/id/product_name; then
    echo "[HYBRID] ASUS laptop detected: $(cat /sys/class/dmi/id/product_name)"
    echo "[HYBRID] Companion packages worth installing separately:"
    echo "         - asusctl              (fan curves, charge limit, keyboard backlight, animations)"
    echo "         - supergfxctl          (GPU mode switcher: Hybrid / Integrated / Vfio)"
    echo "         - rog-control-center   (GUI for the above)"
fi

echo "[HYBRID] Done. Reboot recommended."
