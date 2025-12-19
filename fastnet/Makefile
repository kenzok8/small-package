#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_ARCH_FASTNET:=$(ARCH)

PKG_NAME:=fastnet
PKG_VERSION:=0.7.5
PKG_RELEASE:=3

PKG_SOURCE:=$(PKG_NAME)-binary-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=http://dl.istoreos.com/binary/fastnet/
PKG_HASH:=15d2beee307af62e8756fa5c4e7e2c2a4c2e381d935102e0927e181de26719a2

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-binary-$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=Web Servers/Proxies
	TITLE:=FastNet - network test Web UI
	DEPENDS:=@(arm||x86_64||aarch64)
endef

define Package/$(PKG_NAME)/description
  FastNet provides network testing tools and a Web UI.
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/fastnet
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	[ -f /etc/uci-defaults/fastnet ] && /etc/uci-defaults/fastnet && rm -f /etc/uci-defaults/fastnet
	exit 0
fi
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/config $(1)/etc/init.d $(1)/etc/uci-defaults
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/fastnet.$(PKG_ARCH_FASTNET) $(1)/usr/sbin/FastNet
	$(INSTALL_CONF) ./files/fastnet.config $(1)/etc/config/fastnet
	$(INSTALL_BIN) ./files/fastnet.init $(1)/etc/init.d/fastnet
	$(INSTALL_BIN) ./files/fastnet.uci-default $(1)/etc/uci-defaults/fastnet
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
