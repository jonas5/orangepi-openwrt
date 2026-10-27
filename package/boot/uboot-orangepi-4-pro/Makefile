# SPDX-License-Identifier: GPL-2.0-only
include $(TOPDIR)/rules.mk

PKG_NAME:=uboot-orangepi-4-pro
PKG_VERSION:=1.1.0
PKG_RELEASE:=1

PKG_FLAGS:=nonshared

include $(INCLUDE_DIR)/package.mk

define Package/uboot-orangepi-4-pro
  SECTION:=boot
  CATEGORY:=Boot Loaders
  TITLE:=U-Boot bootloader for Orange Pi 4 Pro
  DEPENDS:=@TARGET_sunxi_cortexa53
  HIDDEN:=1
  DEFAULT:=y if TARGET_sunxi_cortexa53_DEVICE_xunlong_orangepi-4-pro
endef

define Package/uboot-orangepi-4-pro/description
  Prebuilt Allwinner A733 U-Boot bootloader files for Orange Pi 4 Pro
endef

define Build/Compile
endef

define Build/InstallDev
	$(INSTALL_DIR) $(STAGING_DIR_IMAGE)
	$(CP) ./files/boot0_sdcard.fex $(STAGING_DIR_IMAGE)/xunlong_orangepi-4-pro-boot0_sdcard.fex
	$(CP) ./files/boot_package.fex $(STAGING_DIR_IMAGE)/xunlong_orangepi-4-pro-boot_package.fex
	$(CP) ./files/boot.scr $(STAGING_DIR_IMAGE)/xunlong_orangepi-4-pro-boot.scr
	$(CP) ./files/orangepiEnv.txt $(STAGING_DIR_IMAGE)/xunlong_orangepi-4-pro-orangepiEnv.txt
	dd if=/dev/zero of=$(STAGING_DIR_IMAGE)/xunlong_orangepi-4-pro-u-boot-with-spl.bin bs=1M count=20 status=none
	dd if=./files/boot0_sdcard.fex of=$(STAGING_DIR_IMAGE)/xunlong_orangepi-4-pro-u-boot-with-spl.bin bs=8k seek=1 conv=notrunc status=none
	dd if=./files/boot_package.fex of=$(STAGING_DIR_IMAGE)/xunlong_orangepi-4-pro-u-boot-with-spl.bin bs=8k seek=2050 conv=notrunc status=none
endef

define Package/uboot-orangepi-4-pro/install
	$(INSTALL_DIR) $(1)/boot
	$(CP) ./files/boot.scr $(1)/boot/
	$(CP) ./files/orangepiEnv.txt $(1)/boot/
endef

$(eval $(call BuildPackage,uboot-orangepi-4-pro))
