#
# Copyright (C) 2015-2016 OpenWrt.org
# Copyright (C) 2026 jjm2473@gmail.com
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_ARCH_BAIDUDRIVE:=$(ARCH)

PKG_NAME:=baidudrive
PKG_VERSION:=1.0.5
PKG_RELEASE:=1
PKG_SOURCE:=$(PKG_NAME)-binary-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/istoreos/istoreos-app-hub/releases/download/baidudrive-runtime-v$(PKG_VERSION)/
PKG_HASH:=895c0482ae2c4aa08c94814c73b331397e9fc1ff49858327f0c1b2080031e4fe
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-binary-$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0
STRIP:=true
RSTRIP:=:

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=Web Servers/Proxies
	TITLE:=BaiduDrive
	DEPENDS:=@(x86_64||aarch64) +curl
	URL:=https://github.com/linkease/istore-packages
endef

define Package/$(PKG_NAME)/description
  BaiduDrive provides a Baidu Netdisk Web UI for iStoreOS.
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/baidudrive
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh
if [ "$${IPKG_INSTROOT}" = "" ]; then
	if [ "$$(readlink /usr/share/linkeasefull/desktop-apps.d/10-baidudrive-plugin.json 2>/dev/null)" = "/usr/share/baidudrive/baidudrive-plugin.json" ]; then
		rm -f /usr/share/linkeasefull/desktop-apps.d/10-baidudrive-plugin.json
	fi
fi
exit 0
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/usr/libexec/baidudrive $(1)/usr/share/baidudrive/www $(1)/usr/share/linkeasefull/desktop-apps.d $(1)/opt/baidunas-sdk $(1)/opt/baidunas-glibc $(1)/etc/init.d $(1)/etc/uci-defaults $(1)/etc/config
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/baidudrive.$(PKG_ARCH_BAIDUDRIVE) $(1)/usr/sbin/baidudrive
	$(CP) $(PKG_BUILD_DIR)/web/dist/. $(1)/usr/share/baidudrive/www/
	$(INSTALL_DATA) ./files/baidudrive-plugin.json $(1)/usr/share/baidudrive/baidudrive-plugin.json
	ln -sf /usr/share/baidudrive/baidudrive-plugin.json $(1)/usr/share/linkeasefull/desktop-apps.d/10-baidudrive-plugin.json
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/nas_sdk/$(PKG_ARCH_BAIDUDRIVE)/baiduNas $(1)/opt/baidunas-sdk/baiduNas
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/nas_sdk/$(PKG_ARCH_BAIDUDRIVE)/P2PClient.bin $(1)/opt/baidunas-sdk/P2PClient.bin
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/nas_sdk/$(PKG_ARCH_BAIDUDRIVE)/libkernel.so $(1)/opt/baidunas-sdk/libkernel.so
	$(CP) $(PKG_BUILD_DIR)/glibc/$(PKG_ARCH_BAIDUDRIVE)/. $(1)/opt/baidunas-glibc/
	$(LN) /usr/sbin/baidudrive $(1)/opt/baidunas-sdk/P2PClient
	$(INSTALL_BIN) ./files/sdk-init.sh $(1)/usr/libexec/baidudrive/sdk-init.sh
	$(INSTALL_BIN) ./files/baidudrive.init $(1)/etc/init.d/baidudrive
	$(INSTALL_BIN) ./files/baidudrive.uci-default $(1)/etc/uci-defaults/09-baidudrive
	$(INSTALL_CONF) ./files/baidudrive.config $(1)/etc/config/baidudrive
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
