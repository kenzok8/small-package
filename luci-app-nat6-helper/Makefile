include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-nat6-helper
PKG_VERSION:=v1.2
PKG_RELEASE:=1

PKG_LICENSE:=MIT License

LUCI_TITLE:=LuCI support for nat6
LUCI_DEPENDS:=+ip6tables +kmod-ipt-nat6 
LUCI_PKGARCH:=all

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature

