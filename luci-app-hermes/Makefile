
include $(TOPDIR)/rules.mk

PKG_VERSION:=1.0.0-r20240101
PKG_RELEASE:=

LUCI_TITLE:=LuCI support for Hermes
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+docker +dockerd +luci-lib-taskd

define Package/luci-app-hermes/conffiles
/etc/config/hermes
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
