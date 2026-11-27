
include $(TOPDIR)/rules.mk

PKG_VERSION:=0.1.13
PKG_RELEASE:=3

LUCI_TITLE:=LuCI support for OpenClaw Launcher
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+luci-base +luci-compat +luci-lib-taskd +curl +ca-bundle +tar +xz-utils +jsonfilter +git +git-http +ttyd +ks-cli +mise-runtime +coreutils-timeout +coreutils-stat +libstdcpp +libatomic
LUCI_EXTRA_DEPENDS:=mise-runtime (>=0.1.1-$(if $(CONFIG_USE_APK),r)2)

define Build/Prepare/luci-app-openclawmgr
	chmod 0755 $(PKG_BUILD_DIR)/root/usr/share/openclawmgr/gateway.sh
	chmod 0755 $(PKG_BUILD_DIR)/root/usr/share/openclawmgr/npm-lifecycle.sh
endef

define Package/luci-app-openclawmgr/conffiles
/etc/config/openclawmgr
endef

define Package/luci-app-openclawmgr/prerm
#!/bin/sh
/etc/init.d/openclawmgr stop >/dev/null 2>&1 || true
exit 0
endef

define Package/luci-app-openclawmgr/postrm
#!/bin/sh
rm -f /tmp/luci-indexcache /tmp/luci-modulecache/* 2>/dev/null
exit 0
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
