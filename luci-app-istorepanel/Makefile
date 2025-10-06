

include $(TOPDIR)/rules.mk

PKG_VERSION:=1.0.6-20250406
PKG_RELEASE:=

LUCI_TITLE:=LuCI support for 1Panel
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+lsblk +zoneinfo-asia +docker +dockerd +luci-lib-taskd +luci-lib-docker

define Package/luci-app-istorepanel/conffiles
/etc/config/istorepanel
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
