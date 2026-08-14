include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-pushbot
PKG_VERSION:=5.13
PKG_RELEASE:=3

PKG_MAINTAINER:=tty228 <tty228@yeah.net>  zzsj0928

# OpenWrt 23.05 的 luci.mk 版本规则只取 PKG_VERSION（忽略 PKG_RELEASE），
# 导致 GitHub Action 编译出的 ipk 没有 r 小版本（5.12 vs 5.12-r10）。
# 用 override VERSION 强制统一为 PKG_VERSION-rPKG_RELEASE。注意：必须
# 写在 include luci.mk 之前——luci.mk 末尾会立即 eval BuildPackage，
# 其 ipk 命名/control 里的 $(VERSION) 在那一刻固化，写后面就晚了。
# luci.mk 的 VERSION:= 是普通赋值（被 override 压住），且本值在新版
# luci.mk 与 i18n 子包（PKG_PO_VERSION）下与默认一致，不影响 apk/新版。
override VERSION:=$(if $(PKG_RELEASE),$(PKG_VERSION)-r$(PKG_RELEASE),$(PKG_VERSION))

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
