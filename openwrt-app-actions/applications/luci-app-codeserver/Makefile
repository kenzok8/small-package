

include $(TOPDIR)/rules.mk

PKG_VERSION:=1.0.0-20221121
PKG_RELEASE:=

LUCI_TITLE:=LuCI support for CodeServer
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+docker +luci-lib-taskd

define Package/luci-app-codeserver/conffiles
/etc/config/codeserver
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
