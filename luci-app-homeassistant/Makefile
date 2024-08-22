

include $(TOPDIR)/rules.mk

PKG_VERSION:=1.1.2-20240822
PKG_RELEASE:=

LUCI_TITLE:=LuCI support for homeassistant
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+lsblk +docker +dockerd +luci-lib-taskd

define Package/luci-app-homeassistant/conffiles
/etc/config/homeassistant
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
