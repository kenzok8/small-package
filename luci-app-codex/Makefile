include $(TOPDIR)/rules.mk

PKG_VERSION:=0.1.0-r3
PKG_RELEASE:=

LUCI_TITLE:=LuCI support for OpenAI Codex
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+codex +luci-app-mise +luci-compat +luci-lib-taskd +luci-lib-linkeaseauth +linkease-app-entry
LUCI_EXTRA_DEPENDS:=mise-runtime (>=0.1.1-$(if $(CONFIG_USE_APK),r)2), luci-lib-linkeaseauth (>=1.2.1-r5)
LUCI_MINIFY_CSS:=0
LUCI_MINIFY_JS:=0

define Package/luci-app-codex/conffiles
/etc/config/codex
endef

define Package/luci-app-codex/postrm
#!/bin/sh
rm -f /tmp/luci-indexcache /tmp/luci-modulecache/* 2>/dev/null
exit 0
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
