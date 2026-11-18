include $(TOPDIR)/rules.mk

PKG_VERSION:=0.0.1-r20261118
PKG_RELEASE:=

PKG_MAINTAINER:=wanvfx

LUCI_TITLE:=LuCI support for Agent2API
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+luci-base +luci-compat +docker +dockerd +luci-lib-taskd +lsblk

define Package/luci-app-agent2api/conffiles
/etc/config/agent2api
endef

define Package/luci-app-agent2api/prerm
#!/bin/sh
/usr/libexec/istorec/agent2api.sh stop
exit 0
endef

define Package/luci-app-agent2api/postrm
#!/bin/sh
rm -f /tmp/luci-indexcache /tmp/luci-modulecache/*
exit 0
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
