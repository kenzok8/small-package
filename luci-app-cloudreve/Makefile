# Copyright 2026 - luci-app-cloudreve contributors

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-cloudreve
LUCI_TITLE:=LuCI support for Cloudreve
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+luci-base +luci-compat +wget +ca-bundle +tar +lsblk

PKG_MAINTAINER:=RtrBug
PKG_VERSION:=0.0.1-r20260920
PKG_RELEASE:=

define Package/luci-app-cloudreve/conffiles
/etc/config/cloudreve
endef

define Package/luci-app-cloudreve/prerm
#!/bin/sh
# 卸载前先停服务，避免残留进程占着端口
/etc/init.d/cloudreve stop >/dev/null 2>&1 || true
/etc/init.d/cloudreve disable >/dev/null 2>&1 || true
exit 0
endef

define Package/luci-app-cloudreve/postrm
#!/bin/sh
# 清 LuCI 缓存，否则菜单会残留
rm -f /tmp/luci-indexcache
rm -rf /tmp/luci-modulecache
exit 0
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
