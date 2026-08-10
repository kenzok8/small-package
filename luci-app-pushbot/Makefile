include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-pushbot
PKG_VERSION:=5.12
PKG_RELEASE:=9

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

# OpenWrt 23.05 的 luci.mk 版本规则只取 PKG_VERSION（忽略 PKG_RELEASE），
# 导致 GitHub Action 编译出的 ipk 没有 r 小版本（5.12 vs 5.12-r8）。
# 用 override VERSION 强制统一为 PKG_VERSION-rPKG_RELEASE：luci.mk 的
# VERSION:= 是普通赋值（会被 override 压住），且本值在新版 luci.mk 与
# i18n 子包（PKG_PO_VERSION）下与默认一致，所有 OpenWrt 版本输出相同。
override VERSION:=$(if $(PKG_RELEASE),$(PKG_VERSION)-r$(PKG_RELEASE),$(PKG_VERSION))

# call BuildPackage - OpenWrt buildroot signature
