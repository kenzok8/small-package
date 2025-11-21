

include $(TOPDIR)/rules.mk

PKG_VERSION:=1.1.7-r1
PKG_RELEASE:=

LUCI_TITLE:=LuCI support for shadowrt
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+lsblk +docker +dockerd +docker-lan-bridge +luci-lib-taskd

define Package/luci-app-shadowrt/conffiles
/etc/config/shadowrt
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature

