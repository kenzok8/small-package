

include $(TOPDIR)/rules.mk

PKG_VERSION:=1.0.0-20221212
PKG_RELEASE:=

LUCI_TITLE:=LuCI support for Excalidraw
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+docker +luci-lib-taskd +luci-lib-docker +docker-compose

define Package/luci-app-excalidraw/conffiles
/etc/config/excalidraw
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
