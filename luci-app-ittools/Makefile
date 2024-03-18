

include $(TOPDIR)/rules.mk

PKG_VERSION:=1.0.2-20231208
PKG_RELEASE:=

LUCI_TITLE:=LuCI support for ITTools
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+lsblk +docker +dockerd +luci-lib-taskd +luci-lib-docker

define Package/luci-app-ittools/conffiles
/etc/config/ittools
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
