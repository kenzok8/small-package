include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-xray-fw4
PKG_VERSION:=2.0.0
PKG_RELEASE:=1

PKG_LICENSE:=MPLv2
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=yichya <mail@yichya.dev>
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=Custom
	CATEGORY:=Extra packages
	TITLE:=LuCI Support for Xray
	DEPENDS:=firewall4 +kmod-nft-tproxy +luci-app-xray-shared
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	LuCI Support for Xray (Client-side Rendered) (fw4 variant).
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
if [[ -z "$${IPKG_INSTROOT}" ]]; then
	if [[ -f /etc/uci-defaults/xray_fw4 ]]; then
		( . /etc/uci-defaults/xray_fw4 ) && rm -f /etc/uci-defaults/xray_fw4
	fi
	rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
fi
exit 0
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/xray_fw4
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./root/etc/init.d/xray_fw4 $(1)/etc/init.d/xray_fw4
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./root/etc/config/xray_fw4 $(1)/etc/config/xray_fw4
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./root/etc/uci-defaults/xray_fw4 $(1)/etc/uci-defaults/xray_fw4
	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_BIN) ./root/etc/hotplug.d/iface/01-transparent-proxy-ipset.fw4 $(1)/etc/hotplug.d/iface/01-transparent-proxy-ipset
	$(INSTALL_DIR) $(1)/etc/nftables.d
	$(LN) /usr/share/xray/include.nft $(1)/etc/nftables.d/99-xray.nft
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view
	$(INSTALL_DATA) ./root/www/luci-static/resources/view/xray_fw4.js $(1)/www/luci-static/resources/view/xray_fw4.js
	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DATA) ./root/usr/share/luci/menu.d/luci-app-xray.json $(1)/usr/share/luci/menu.d/luci-app-xray.json
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./root/usr/share/rpcd/acl.d/luci-app-xray.json $(1)/usr/share/rpcd/acl.d/luci-app-xray.json
	$(INSTALL_DIR) $(1)/usr/share/xray
	$(INSTALL_DATA) ./root/usr/share/xray/include.nft $(1)/usr/share/xray/include.nft
	$(INSTALL_BIN) ./root/usr/share/xray/firewall_include.ut $(1)/usr/share/xray/firewall_include.ut
	$(INSTALL_BIN) ./root/usr/share/xray/gen_config.uc $(1)/usr/share/xray/gen_config.uc
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
