#
# Copyright (C) 2026 iStoreOS
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=linkease-app-entry
# This lightweight runtime is released independently from the full desktop.
PKG_VERSION:=3.0.22
PKG_RELEASE:=1

ARCH_HEXCODE:=
ifeq ($(ARCH),x86_64)
ARCH_HEXCODE=8664
LINKEASE_RUNTIME_ARCH:=amd64
PKG_HASH:=4c8f0e64c0dce16a8a4aa51eadd21b597efe7edbab207cd97e21d3ad55b38dd5
else ifeq ($(ARCH),aarch64)
ARCH_HEXCODE=aa64
LINKEASE_RUNTIME_ARCH:=arm64
PKG_HASH:=d05e8b1a0b9c46de01e298ab14b4d92c1591e86e935bca701c68875b0911240c
endif

PKG_SOURCE_VERSION:=$(ARCH_HEXCODE)
PKG_SOURCE:=linkease-app-entry-runtime-$(PKG_VERSION)-linux-$(LINKEASE_RUNTIME_ARCH).tar.gz
PKG_SOURCE_URL:=https://github.com/istoreos/istoreos-app-hub/releases/download/linkease-app-entry-runtime-v$(PKG_VERSION)/
PKG_BUILD_DIR:=$(BUILD_DIR)/linkease-app-entry-runtime-$(PKG_VERSION)-linux-$(LINKEASE_RUNTIME_ARCH)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=Web Servers/Proxies
	TITLE:=LinkEase application entry arbiter and fallback gateway
	DEPENDS:=@(x86_64||aarch64) +ca-bundle +luci-lib-linkeaseauth
	PKGARCH:=all
	URL:=https://www.linkease.com/
endef

define Package/$(PKG_NAME)/description
  Owns the shared /apps listener, launches LinkEaseFull directly when healthy,
  and runs the manifest-driven fallback gateway only when LinkEaseFull is not available.
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/linkease_app_entry
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	[ -f /etc/uci-defaults/linkease-app-entry ] && /etc/uci-defaults/linkease-app-entry && rm -f /etc/uci-defaults/linkease-app-entry
fi
exit 0
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/config $(1)/etc/init.d $(1)/etc/uci-defaults
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/linkease-app-entry $(1)/usr/sbin/linkease-app-entry
	$(INSTALL_CONF) ./files/linkease-app-entry.config $(1)/etc/config/linkease_app_entry
	$(INSTALL_BIN) ./files/linkease-app-entry.init $(1)/etc/init.d/linkease-app-entry
	$(INSTALL_BIN) ./files/linkease-app-entry.uci-default $(1)/etc/uci-defaults/linkease-app-entry
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
