# Copyright 2025 - tkme <tkme@qq.com>

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-zdinnav
LUCI_TITLE:=LuCI support for ZdinNav
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+lsblk +docker +dockerd +luci-lib-taskd +luci-lib-docker +docker-compose +luci-compat

PKG_MAINTAINER:=tkme <tkme@qq.com>

PKG_VERSION:=1.1.1
PKG_RELEASE:=1

define Package/luci-app-zdinnav/conffiles
/etc/config/zdinnav
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
