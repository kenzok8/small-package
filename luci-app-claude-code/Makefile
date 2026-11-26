include $(TOPDIR)/rules.mk

PKG_VERSION:=0.1.0-r3
PKG_RELEASE:=

LUCI_TITLE:=LuCI support for Anthropic Claude Code
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+claude-code +luci-app-mise +luci-compat +luci-lib-taskd +luci-lib-linkeaseauth +linkease-app-entry
LUCI_EXTRA_DEPENDS:=mise-runtime (>=0.1.1-$(if $(CONFIG_USE_APK),r)2), luci-lib-linkeaseauth (>=1.2.1-r5)
LUCI_MINIFY_CSS:=0
LUCI_MINIFY_JS:=0

define Package/luci-app-claude-code/conffiles
/etc/config/claude
endef

define Package/luci-app-claude-code/postrm
#!/bin/sh
rm -f /tmp/luci-indexcache /tmp/luci-modulecache/* 2>/dev/null
exit 0
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
