

include $(TOPDIR)/rules.mk

PKG_VERSION:=1.0.8-20250207
PKG_RELEASE:=

LUCI_TITLE:=LuCI support for OpenWebUI
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+lsblk +zoneinfo-asia +docker +dockerd +luci-lib-taskd +luci-lib-docker

define Package/luci-app-openwebui/conffiles
/etc/config/openwebui
endef

define Package/luci-app-openwebui/prerm
#!/bin/sh
/usr/libexec/istorec/openwebui.sh stop
exit 0
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
