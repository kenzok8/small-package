
include $(TOPDIR)/rules.mk

PKG_VERSION:=1.0.0-20230404
PKG_RELEASE:=
PKG_MAINTAINER:=jjm2473 <jjm2473@gmail.com>

LUCI_TITLE:=Generate MAC address for WAN
LUCI_PKGARCH:=all

define Package/luci-app-wan-mac/conffiles
/etc/config/wan_mac
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
