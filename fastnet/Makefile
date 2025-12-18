#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_ARCH_FASTNET:=$(ARCH)

PKG_NAME:=fastnet
# use PKG_SOURCE_DATE instead of PKG_VERSION for compatible
PKG_SOURCE_DATE:=0.7.2
PKG_RELEASE:=2

PKG_SOURCE:=$(PKG_NAME)-binary-$(PKG_SOURCE_DATE).tar.gz
PKG_SOURCE_URL:=http://dl.istoreos.com/binary/fastnet/
PKG_HASH:=aa8c0a3aa6885536d0ab9efc25df4191de78e3d0bc1077607874f64100d82f98

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-binary-$(PKG_SOURCE_DATE)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=Web Servers/Proxies
	TITLE:=FastNet - network test Web UI
	DEPENDS:=@(arm||x86_64||aarch64)
	PKGARCH:=all
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
