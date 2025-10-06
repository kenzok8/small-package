

include $(TOPDIR)/rules.mk

PKG_VERSION:=1.0.1-20240822
PKG_RELEASE:=

LUCI_TITLE:=LuCI support for CloudDrive2
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+mount-utils +lsblk +docker +dockerd +luci-lib-taskd

define Package/luci-app-clouddrive2/conffiles
/etc/config/clouddrive2
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature

