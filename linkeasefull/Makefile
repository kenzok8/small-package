#
# Copyright (C) 2026 iStoreOS
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_ARCH_LINKEASE:=$(ARCH)

PKG_NAME:=linkeasefull
# use PKG_SOURCE_DATE instead of PKG_VERSION for compitable
PKG_SOURCE_DATE:=3.0.11
PKG_RELEASE:=1

ARCH_HEXCODE:=
ifeq ($(ARCH),x86_64)
ARCH_HEXCODE=8664
LINKEASE_RUNTIME_ARCH:=amd64
PKG_HASH:=506028ba73983bfba264231bd2276152e1525b5f7dcb023f2256a8471bb856b0
else ifeq ($(ARCH),aarch64)
ARCH_HEXCODE=aa64
LINKEASE_RUNTIME_ARCH:=arm64
PKG_HASH:=4dae89c14b3a8d56bae64b751eb67aa4ddf06526aed30aa6e86c9bbe51dde389
endif

PKG_SOURCE_VERSION:=$(ARCH_HEXCODE)
PKG_SOURCE:=linkease-runtime-$(PKG_SOURCE_DATE)-linux-$(LINKEASE_RUNTIME_ARCH).tar.gz
PKG_SOURCE_URL:=https://github.com/istoreos/istoreos-app-hub/releases/download/linkeasefull-runtime-v$(PKG_SOURCE_DATE)/
PKG_BUILD_DIR:=$(BUILD_DIR)/linkease-runtime-$(PKG_SOURCE_DATE)-linux-$(LINKEASE_RUNTIME_ARCH)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=Web Servers/Proxies
	TITLE:=LinkEase Full - the local web desktop
	DEPENDS:=@(x86_64||aarch64) +linkease-common-bin +ca-bundle +cifsmount +kmod-fs-cifs
	PKGARCH:=all
	URL:=https://www.linkease.com/
endef

define Package/$(PKG_NAME)/description
  LinkEase Full provides the local web desktop entry for LinkEase and reuses the shared LinkEase file entry.
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/linkeasefull
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	[ -f /etc/uci-defaults/linkeasefull ] && /etc/uci-defaults/linkeasefull && rm -f /etc/uci-defaults/linkeasefull
	exit 0
fi
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin $(1)/usr/libexec/linkeasefull/linkmount_bin $(1)/etc/config $(1)/etc/init.d $(1)/etc/uci-defaults
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/linkease-full $(1)/usr/bin/linkease-full
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/linkremote-agent $(1)/usr/bin/linkremote-agent
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/hostlink $(1)/usr/bin/hostlink
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/linkmount_bin/linkmount_bin $(1)/usr/libexec/linkeasefull/linkmount_bin/linkmount_bin
	$(CP) $(PKG_BUILD_DIR)/linkmount_bin/lib $(1)/usr/libexec/linkeasefull/linkmount_bin/lib
	$(CP) $(PKG_BUILD_DIR)/linkmount_bin/ver.json $(1)/usr/libexec/linkeasefull/linkmount_bin/ver.json
	$(INSTALL_CONF) ./files/linkeasefull.config $(1)/etc/config/linkeasefull
	$(INSTALL_BIN) ./files/linkeasefull.init $(1)/etc/init.d/linkeasefull
	$(INSTALL_BIN) ./files/linkeasefull.uci-default $(1)/etc/uci-defaults/linkeasefull
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
