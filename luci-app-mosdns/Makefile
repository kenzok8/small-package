include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-mosdns
PKG_VERSION:=1.0
PKG_RELEASE:=5

LUCI_TITLE:=LuCI Support for mosdns
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+mosdns +jsonfilter +bash

define Package/$(PKG_NAME)/conffiles
/etc/mosdns/config.yaml
/etc/config/mosdns
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
