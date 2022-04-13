include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-webdav
PKG_VERSION:=4.1.1
PKG_RELEASE:=1
PKG_PO_VERSION:=$(PKG_VERSION)-$(PKG_RELEASE)

PKG_LICENSE:=MIT
PKG_MAINTAINER:=hacdias <hacdias@icloud.com>

LUCI_TITLE:=LuCI Support for webdav server
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+webdav

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
