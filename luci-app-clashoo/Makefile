include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-clashoo
PKG_VERSION:=1.27.1
PKG_RELEASE:=1
PKG_MAINTAINER:=kenzok8

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-clashoo
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=LuCI app for Clashoo
  DEPENDS:=+luci-base +clashoo
  PKGARCH:=all
  MAINTAINER:=kenzok8
endef

define Package/luci-app-clashoo/description
  LuCI web interface for Clashoo
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/luci-app-clashoo/install
	$(INSTALL_DIR) $(1)/usr/share/rpcd/ucode
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DIR) $(1)/www/luci-static/resources/tools
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/clashoo
	$(INSTALL_DIR) $(1)/www/luci-static/resources/cm/mode
	$(INSTALL_DIR) $(1)/www/luci-static/resources/cm/addon
	$(INSTALL_DIR) $(1)/www/luci-static/clashoo

	$(INSTALL_BIN) ./root/usr/share/rpcd/ucode/luci.clashoo $(1)/usr/share/rpcd/ucode/luci.clashoo
	$(INSTALL_DATA) ./root/usr/share/rpcd/acl.d/luci-app-clashoo.json $(1)/usr/share/rpcd/acl.d/luci-app-clashoo.json
	$(INSTALL_DATA) ./root/usr/share/luci/menu.d/luci-app-clashoo.json $(1)/usr/share/luci/menu.d/luci-app-clashoo.json

	$(INSTALL_DATA) ./htdocs/luci-static/resources/tools/clashoo.js $(1)/www/luci-static/resources/tools/clashoo.js
	$(INSTALL_DATA) ./htdocs/luci-static/resources/view/clashoo/* $(1)/www/luci-static/resources/view/clashoo/
	$(INSTALL_DATA) ./htdocs/luci-static/resources/cm/codemirror.js $(1)/www/luci-static/resources/cm/codemirror.js
	$(INSTALL_DATA) ./htdocs/luci-static/resources/cm/codemirror.css $(1)/www/luci-static/resources/cm/codemirror.css
	$(INSTALL_DATA) ./htdocs/luci-static/resources/cm/mode/* $(1)/www/luci-static/resources/cm/mode/
	$(INSTALL_DATA) ./htdocs/luci-static/resources/cm/addon/* $(1)/www/luci-static/resources/cm/addon/
	$(INSTALL_DATA) ./htdocs/luci-static/clashoo/logo.png $(1)/www/luci-static/clashoo/logo.png
endef

define Package/luci-app-clashoo/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	rm -rf /tmp/luci-indexcache /tmp/luci-modulecache
	# reload (not restart) rpcd so the LuCI login session survives the upgrade —
	# rpcd restart drops every ubus session and forces a re-login (issue #12).
	# reload still picks up the new ucode backend + ACL. uhttpd needs nothing:
	# updated static assets are served on the next request.
	/etc/init.d/rpcd reload >/dev/null 2>&1 || true
fi
exit 0
endef

define Package/luci-i18n-clashoo-zh-cn
	SECTION:=luci
	CATEGORY:=LuCI
	TITLE:=luci-app-clashoo - Simplified Chinese (zh-cn)
	DEPENDS:=+luci-app-clashoo
	PKGARCH:=all
endef

define Package/luci-i18n-clashoo-zh-cn/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) ./po/zh-cn/clashoo.zh-cn.lmo $(1)/usr/lib/lua/luci/i18n
endef

define Package/luci-i18n-clashoo-zh-cn/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	# just clear the LuCI cache so the new translations load on next request;
	# no service restart needed (and none that would drop the login session).
	rm -rf /tmp/luci*
fi
exit 0
endef

$(eval $(call BuildPackage,luci-app-clashoo))
$(eval $(call BuildPackage,luci-i18n-clashoo-zh-cn))
