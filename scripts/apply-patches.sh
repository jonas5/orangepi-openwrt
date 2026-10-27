#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPENWRT_DIR="${1:-.}"

if [ ! -f "${OPENWRT_DIR}/Makefile" ] || [ ! -d "${OPENWRT_DIR}/target/linux/sunxi" ]; then
    echo "Error: '${OPENWRT_DIR}' does not appear to be an OpenWrt root directory."
    echo "Usage: $0 [/path/to/openwrt]"
    exit 1
fi

OPENWRT_DIR="$(cd "${OPENWRT_DIR}" && pwd)"
echo "=== Applying Orange Pi 4 Pro patches to OpenWrt tree at: ${OPENWRT_DIR} ==="

# 1. Apply OpenWrt target modifications
echo "Applying OpenWrt sunxi target patch..."
patch -d "${OPENWRT_DIR}" -p1 -N --dry-run --silent < "${SCRIPT_DIR}/patches/openwrt/0001-sunxi-add-orange-pi-4-pro-support.patch" 2>/dev/null && \
    patch -d "${OPENWRT_DIR}" -p1 < "${SCRIPT_DIR}/patches/openwrt/0001-sunxi-add-orange-pi-4-pro-support.patch" || \
    echo "OpenWrt target patch already applied or partially present, skipping."

# 2. Install SD card layout script
echo "Installing sun60i SD card image script..."
cp -v "${SCRIPT_DIR}/target/linux/sunxi/image/gen_sun60i_sdcard_img.sh" "${OPENWRT_DIR}/target/linux/sunxi/image/"
chmod +x "${OPENWRT_DIR}/target/linux/sunxi/image/gen_sun60i_sdcard_img.sh"

# 3. Copy kernel 6.18 mainline patch
echo "Installing kernel 6.18 patch for Orange Pi 4 Pro (Allwinner A733)..."
mkdir -p "${OPENWRT_DIR}/target/linux/sunxi/patches-6.18"
cp -v "${SCRIPT_DIR}/patches/kernel/950-allwinner-a733-orangepi-4-pro-6.18-mainline.patch" "${OPENWRT_DIR}/target/linux/sunxi/patches-6.18/"

# 4. Copy U-Boot / bootloader package
echo "Installing uboot-orangepi-4-pro package..."
mkdir -p "${OPENWRT_DIR}/package/boot"
rm -rf "${OPENWRT_DIR}/package/boot/uboot-orangepi-4-pro"
cp -r "${SCRIPT_DIR}/package/boot/uboot-orangepi-4-pro" "${OPENWRT_DIR}/package/boot/"

# 5. Apply default config if requested or missing
if [ ! -f "${OPENWRT_DIR}/.config" ]; then
    echo "Installing default Orange Pi 4 Pro OpenWrt configuration..."
    cp -v "${SCRIPT_DIR}/configs/orangepi_4pro_defconfig" "${OPENWRT_DIR}/.config"
    make -C "${OPENWRT_DIR}" defconfig
fi

echo "=== Orange Pi 4 Pro support installed successfully! ==="
