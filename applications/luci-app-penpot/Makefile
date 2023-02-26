

include $(TOPDIR)/rules.mk

PKG_VERSION:=1.0.0-20221122
PKG_RELEASE:=

LUCI_TITLE:=LuCI support for Penpot
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+docker +luci-lib-taskd +docker-compose

define Package/luci-app-penpot/conffiles
/etc/config/penpot
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
