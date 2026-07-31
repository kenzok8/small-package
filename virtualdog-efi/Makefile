#
# Copyright (C) 2026
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=virtualdog-efi
PKG_VERSION:=0.0.1
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/Carseason/openwrt-packages/releases/download/prebuilt/
PKG_HASH:=e19f906a2cb312a37b8416b055757a151b54f0417524c90cd847fac4a7ccfbb5
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKGARCH:=all

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=Web Servers/Proxies
	TITLE:=VirtualDog ARM64 UEFI firmware
	DEPENDS:=@(x86_64||aarch64)
	URL:=https://example.invalid/virtualdog
endef

define Package/$(PKG_NAME)/description
  VirtualDog ARM64 UEFI firmware for qemu-system-aarch64 virtual machines.
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/share/virtualdog
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/QEMU_EFI.fd $(1)/usr/share/virtualdog/QEMU_EFI.fd
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
