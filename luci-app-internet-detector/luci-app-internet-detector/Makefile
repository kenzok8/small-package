#
# (с) 2025 gSpot (https://github.com/gSpotx2f/luci-app-internet-detector)
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-internet-detector
PKG_VERSION:=1.6.2
PKG_RELEASE:=1
LUCI_TITLE:=LuCI support for internet-detector
LUCI_DEPENDS:=+internet-detector
LUCI_PKGARCH:=all

#include ../../luci.mk
include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
