#
# Copyright (C) 2026
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=virtualdog
PKG_VERSION:=0.0.1
PKG_RELEASE:=
# Point this at the released binary tarball when you publish builds.
PKG_SOURCE:=$(PKG_NAME)-binary-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/Carseason/openwrt-packages/releases/download/prebuilt/
PKG_HASH:=cfc5f3bbab8547157e786a722e85dc39a042652008c9631afaee8a3015c781fe
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-binary-$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

PKG_ARCH_virtualdog:=$(ARCH)

ifeq ($(ARCH),x86_64)
	VIRTUALDOG_QEMU_PKG:=qemu-x86_64-softmmu
else ifeq ($(ARCH),aarch64)
	VIRTUALDOG_QEMU_PKG:=qemu-aarch64-softmmu
endif

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=Web Servers/Proxies
	TITLE:=VirtualDog
	DEPENDS:=@(x86_64||aarch64) +$(VIRTUALDOG_QEMU_PKG) +qemu-img +qemu-bridge-helper +kmod-tun
	URL:=https://example.invalid/virtualdog
endef

define Package/$(PKG_NAME)/description
  VirtualDog provides a web UI and API for managing QEMU/KVM virtual machines on OpenWrt.
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/virtualdog
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/init.d $(1)/etc/uci-defaults $(1)/etc/config
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/virtualdogd.$(PKG_ARCH_virtualdog) $(1)/usr/sbin/virtualdogd
	$(INSTALL_BIN) ./files/virtualdog.init $(1)/etc/init.d/virtualdog
	$(INSTALL_BIN) ./files/virtualdog.uci-default $(1)/etc/uci-defaults/09-virtualdog
	$(INSTALL_CONF) ./files/virtualdog.config $(1)/etc/config/virtualdog
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
