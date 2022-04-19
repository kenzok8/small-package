include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-openvpn-server
PKG_VERSION:=1.0
PKG_RELEASE:=3

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=LuCI
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=LuCI support for OpenVPN Server
  DEPENDS:=+openvpn-openssl +openvpn-easy-rsa-whisky +luci-compat
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	LuCI support for OpenVPN Server.
endef

define Build/Prepare
	$(foreach po,$(wildcard ${CURDIR}/po/zh-cn/*.po), \
		po2lmo $(po) $(PKG_BUILD_DIR)/$(patsubst %.po,%.zh-cn.lmo,$(notdir $(po)));)
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
[ -n "${IPKG_INSTROOT}" ] || {
	(. /etc/uci-defaults/openvpn) && rm -f /etc/uci-defaults/openvpn
	exit 0
}
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/conffiles
/etc/openvpn/
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DATA) ./luasrc/controller/*.lua $(1)/usr/lib/lua/luci/controller/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/openvpn-server
	$(INSTALL_DATA) ./luasrc/model/cbi/openvpn-server/*.lua $(1)/usr/lib/lua/luci/model/cbi/openvpn-server/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/openvpn-server
	$(INSTALL_DATA) ./luasrc/view/openvpn-server/*.htm $(1)/usr/lib/lua/luci/view/openvpn-server/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/openvpn-server.*.lmo $(1)/usr/lib/lua/luci/i18n/
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./root/etc/config/openvpn $(1)/etc/config/openvpn
	$(INSTALL_DIR) $(1)/etc/openvpn/server
	$(INSTALL_DATA) ./root/etc/openvpn/server/psw-file $(1)/etc/openvpn/server/psw-file
	$(INSTALL_DIR) $(1)/etc/openvpn/ovpnadd
	$(INSTALL_DATA) ./root/etc/openvpn/ovpnadd/ovpnadd.conf $(1)/etc/openvpn/ovpnadd/ovpnadd.conf
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./root/etc/uci-defaults/openvpn $(1)/etc/uci-defaults/openvpn
	$(INSTALL_DIR) $(1)/usr/share/openvpn
	$(INSTALL_BIN) ./root/usr/*.sh $(1)/usr/share/openvpn/
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./root/acl.d/* $(1)/usr/share/rpcd/acl.d/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
