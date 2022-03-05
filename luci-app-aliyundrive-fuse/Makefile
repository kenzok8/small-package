include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-aliyundrive-fuse
PKG_VERSION:=0.1.7
PKG_RELEASE:=1
PKG_PO_VERSION:=$(PKG_VERSION)-$(PKG_RELEASE)

PKG_LICENSE:=MIT
PKG_MAINTAINER:=messense <messense@icloud.com>

LUCI_TITLE:=LuCI Support for aliyundrive-fuse
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+aliyundrive-fuse +lua +libuci-lua

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
