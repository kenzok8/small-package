include $(TOPDIR)/rules.mk

PKG_VERSION:=0.1.1
PKG_RELEASE:=1
LUCI_TITLE:=Persistent runtime environments
LUCI_PKGARCH:=all
LUCI_MINIFY_JS:=0
LUCI_MINIFY_CSS:=0
LUCI_DEPENDS:=+luci-base +luci-compat +mise-runtime
LUCI_EXTRA_DEPENDS:=mise-runtime (>=0.1.1-$(if $(CONFIG_USE_APK),r)1)

define Build/Prepare/luci-app-mise
	$(INSTALL_DIR) $(PKG_BUILD_DIR)/root/usr/share/linkease/apps.d
	ln -sf /usr/share/mise/mise-plugin.json $(PKG_BUILD_DIR)/root/usr/share/linkease/apps.d/40-mise.json
	chmod 0755 $(PKG_BUILD_DIR)/root/usr/share/mise/register-desktop.sh
endef

define Package/luci-app-mise/postinst
#!/bin/sh
IPKG_INSTROOT="$${IPKG_INSTROOT:-}" "$${IPKG_INSTROOT:-}/usr/share/mise/register-desktop.sh" register
if [ -z "$${IPKG_INSTROOT:-}" ]; then
	rm -f /tmp/luci-indexcache /tmp/luci-indexcache.*
	rm -rf /tmp/luci-modulecache
	/etc/init.d/rpcd reload >/dev/null 2>&1 || true
fi
exit 0
endef

define Package/luci-app-mise/postrm
#!/bin/sh
if [ -z "$${IPKG_INSTROOT:-}" ]; then
	rm -f /tmp/luci-indexcache /tmp/luci-indexcache.*
	rm -rf /tmp/luci-modulecache
	/etc/init.d/rpcd reload >/dev/null 2>&1 || true
fi
exit 0
endef

define Package/luci-app-mise/prerm
#!/bin/sh
IPKG_INSTROOT="$${IPKG_INSTROOT:-}" "$${IPKG_INSTROOT:-}/usr/share/mise/register-desktop.sh" remove
exit 0
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
