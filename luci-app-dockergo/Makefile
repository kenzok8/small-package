include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI support for DockerGo
LUCI_DEPENDS:=@(aarch64||arm||x86_64) \
	+luci-lib-taskd \
	+curl \
	+ca-bundle \
	+docker +dockerd +cgroupfs-mount \
	+dockerd +cgroupfs-mount
LUCI_PKGARCH:=all
LUCI_MINIFY_JS:=0
LUCI_MINIFY_CSS:=0

PKG_LICENSE:=GPL-2.0-or-later
PKG_MAINTAINER:=DockerGo
PKG_VERSION:=0.1.0
PKG_RELEASE:=1

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
