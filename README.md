# OpenWrt for Orange Pi 4 Pro (Allwinner A733 / sun60iw2)

Official OpenWrt firmware and build harness for the **Orange Pi 4 Pro** powered by the **Allwinner A733** octa-core processor (6× Cortex-A55, 2× Cortex-A76), running on mainline **Linux 6.18.y**.

---

## 1. Hardware & System Status

| Component | Hardware Specification | OpenWrt 6.18 Status | Driver Architecture |
| :--- | :--- | :--- | :--- |
| **CPU / SoC** | Allwinner A733 (6× Cortex-A55, 2× Cortex-A76) | **Working** | Mainline DT, CCU clocks, PCK-600 power domain controller |
| **Ethernet** | Motorcomm YT8531 Gigabit PHY | **Working** | `stmmac` + `motorcomm` (EEE auto-sleep disabled, 0% packet loss) |
| **MicroSD** | SDC0 (`mmc@4020000`) | **Working** | Safe 64MB partition alignment preventing bootloader overwrite |
| **Serial Console** | UART0 (`serial@2500000`) | **Working** | `ttyS0` @ 115200 baud, 8N1 |
| **Wi-Fi** | AIC8800D80 SDIO 4-bit (`mmc@4021000`) | **Excluded by Design** | Handled out-of-tree via standalone private driver package |
| **Bluetooth** | AIC8800D80 UART1 (`serial@2501000`) | **Excluded by Design** | Handled out-of-tree via standalone private driver package |
| **Power Mgmt** | AXP8191 PMIC + PCK-600 | **Working** | Full frequency scaling and power domain gating |

> **Wi-Fi / Bluetooth Architecture & Driver Licenses:**  
> The core OpenWrt base firmware and mainline Linux 6.18 kernel patches are 100% open source. The proprietary FullMAC AIC8800D80 Wi-Fi 6 driver stack and hardware acceleration modules are maintained out-of-tree. Driver licenses and standalone packages can be grabbed below (€23.39 / ~$29.99 USD):  
>  
> <a href="https://buymeacoffee.com/jonas5/e/591989" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="46" style="height: 46px !important;"></a>

---

## 2. Bootloader & Storage Architecture

The Allwinner A733 (`sun60iw2`) utilizes a specific multi-stage boot structure that differs from earlier Allwinner SoCs (such as H3/H5/H6):

```text
SD Card / eMMC Offset Layout:
┌─────────────────┬────────────────────────────────────────────────────────┐
│ Byte Offset     │ Content                                                │
├─────────────────┼────────────────────────────────────────────────────────┤
│ Sector 0        │ MBR / Partition Table (ptgen)                          │
│ Sector 16 (8K)  │ boot0_sdcard.fex (Primary Bootloader / SPL)            │
│ Sector 32800    │ boot_package.fex (~16.4 MB: ATF BL31 + U-Boot 2018.05) │
│ Sector 131072   │ Partition 1: FAT32 Boot (64 MB offset)                 │
│                 │   ├── uImage (OpenWrt FIT Image: Kernel + DTB)         │
│                 │   ├── boot.scr (U-Boot boot script)                    │
│                 │   ├── orangepiEnv.txt (Boot arguments)                 │
│                 │   └── sun60i-a733-orangepi-4-pro.dtb                   │
│ Sector 262144   │ Partition 2: Root Filesystem (ext4 or squashfs)        │
└─────────────────┴────────────────────────────────────────────────────────┘
```

Standard Allwinner OpenWrt targets place the boot partition at 512 KB (`sector 1024`), which immediately overwrites the A733 `boot_package.fex` located at 16.4 MB. This repository provides a custom partition generator (`gen_sun60i_sdcard_img.sh`) that aligns Partition 1 to **64 MB (sector 131072)**, ensuring complete integrity for all boot stages.

---

## 3. Repository Structure

```text
├── .github/
│   └── workflows/
│       └── build.yml               # Automated CI workflow building bootable SD card images
├── configs/
│   └── orangepi_4pro_defconfig     # Minimal OpenWrt configuration for Orange Pi 4 Pro
├── package/
│   └── boot/
│       └── uboot-orangepi-4-pro/   # Prebuilt A733 U-Boot bootloader & script package
├── patches/
│   ├── kernel/
│   │   └── 950-allwinner-a733-orangepi-4-pro-6.18-mainline.patch # Mainline 6.18 kernel patch
│   └── openwrt/
│       └── 0001-sunxi-add-orange-pi-4-pro-support.patch          # OpenWrt target patch
├── scripts/
│   └── apply-patches.sh            # Helper script to inject board support into OpenWrt
├── target/
│   └── linux/
│       └── sunxi/
│           └── image/
│               └── gen_sun60i_sdcard_img.sh # Custom 64MB-offset SD card image generator
└── README.md
```

---

## 4. Building with GitHub Actions

An automated GitHub Actions workflow is provided in `.github/workflows/build.yml`.

1. Go to the **Actions** tab in this GitHub repository.
2. Select **Build OpenWrt for Orange Pi 4 Pro**.
3. Click **Run workflow** (optionally provide a custom tag or release option).
4. When the run finishes, download the build artifacts:
   - `openwrt-sunxi-cortexa53-xunlong_orangepi-4-pro-ext4-sdcard.img.gz`
   - `openwrt-sunxi-cortexa53-xunlong_orangepi-4-pro-squashfs-sdcard.img.gz`
   - `openwrt-sunxi-cortexa53-xunlong_orangepi-4-pro-initramfs-kernel.bin`

---

## 5. Local Build Instructions

### Prerequisites (Ubuntu 22.04 / 24.04 / Debian 12)

```bash
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  build-essential clang flex bison g++ gawk gcc-multilib g++-multilib \
  gettext git libncurses5-dev libssl-dev python3-setuptools python3-dev \
  rsync unzip zlib1g-dev file wget curl zstd dosfstools mtools \
  device-tree-compiler u-boot-tools libelf-dev libyaml-dev pkg-config
```

### Build Steps

```bash
# 1. Clone OpenWrt source
git clone https://git.openwrt.org/openwrt/openwrt.git openwrt
cd openwrt

# 2. Update and install standard package feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 3. Apply Orange Pi 4 Pro patches and bootloader packages
# (Run from inside the openwrt directory, pointing to this repository)
/path/to/orangepi-openwrt/scripts/apply-patches.sh .

# 4. Configure OpenWrt for Orange Pi 4 Pro
cp /path/to/orangepi-openwrt/configs/orangepi_4pro_defconfig .config
make defconfig

# 5. Download package sources
make download -j$(nproc)

# 6. Compile the firmware images
export FORCE_UNSAFE_CONFIGURE=1
make -j$(nproc)
```

The resulting firmware files will be generated in:
`bin/targets/sunxi/cortexa53/`

---

## 6. Flashing & Booting

### Flashing to MicroSD Card

Identify your SD card device (e.g. `/dev/sdX` using `lsblk`):

```bash
# Decompress and flash ext4 image directly:
zcat openwrt-sunxi-cortexa53-xunlong_orangepi-4-pro-ext4-sdcard.img.gz | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync
```

### Serial Console

Connect a 3.3V USB-to-UART adapter to the 3-pin debug header:
- **TX** -> RX on adapter
- **RX** -> TX on adapter
- **GND** -> GND on adapter
- **Baud Rate**: `115200` (8N1)

```bash
picocom -b 115200 /dev/ttyUSB0
```

### Network Default Configuration

- **Interface**: `eth0` (Motorcomm YT8531 Gigabit Ethernet)
- **Role**: LAN
- **Default IP**: `192.168.1.1`
- **Subnet Mask**: `255.255.255.0`
- **DHCP Server**: Enabled (leases `192.168.1.100` – `192.168.1.249`)
- **SSH**: Port `22` (root, no password by default)

---

## 7. Private Driver Pack Integration (Wi-Fi 6 on OpenWrt)

The onboard **AIC8800D80 Wi-Fi 6 (802.11ax) & Bluetooth 5.4** controller is kept in a separate standalone driver pack. It includes:
- Kernel modules compiled specifically for OpenWrt 6.18: `cfg80211.ko`, `sunxi_rfkill.ko`, `aic8800_bsp.ko`, `aic8800_fdrv.ko`, `aic8800_btlpm.ko`
- Official AIC8800D80 microcode firmware binaries (`/lib/firmware/aic8800d80/`)
- Sequenced bring-up script (`/usr/local/bin/aic8800-start.sh`)
- OpenWrt procd auto-boot service (`/etc/init.d/aic8800`)
- Hardware authentication utility (`hw_verify`)

### Grab Driver License (€23.39 / ~$29.99 USD)

<a href="https://buymeacoffee.com/jonas5/e/591989" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="46" style="height: 46px !important;"></a>

### Instant 1-Command Installation on OpenWrt

Once booted into OpenWrt with Ethernet connected, install the driver pack directly:

```bash
wget -qO- https://raccoon.ing/opi4pro-openwrt-wifi-driverpack.tar.gz | tar -zxv
cd opi4pro-openwrt-wifi
./install.sh
```

The installer will:
1. Verify the hardware license against the SoC factory eFuse SID.
2. Deploy the kernel modules to `/lib/modules/$(uname -r)/`.
3. Extract the firmware into `/lib/firmware/aic8800d80/`.
4. Enable and start `/etc/init.d/aic8800`, initializing `wlan0`.

To verify wireless status:
```bash
# Check interface:
ip link show wlan0

# Scan wireless networks:
iw dev wlan0 scan
```

---

## 8. License

The OpenWrt modifications, device tree files, and build scripts are licensed under **GPL-2.0-only** in accordance with OpenWrt and Linux kernel licensing.
