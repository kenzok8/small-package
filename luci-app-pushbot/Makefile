include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-pushbot
PKG_VERSION:=5.10
PKG_RELEASE:=20

PKG_MAINTAINER:=tty228 <tty228@yeah.net>  zzsj0928

LUCI_TITLE:=LuCI support for Pushbot
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+luci-base +iputils-arping +curl +jq

# 汉化包（luci-i18n-*) 版本与主包保持同步
PKG_PO_VERSION:=$(PKG_VERSION)-r$(PKG_RELEASE)

define Package/$(PKG_NAME)/conffiles
/etc/config/pushbot
/usr/bin/pushbot/api/diy.json
/usr/bin/pushbot/api/ipv4.list
/usr/bin/pushbot/api/ipv6.list
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
