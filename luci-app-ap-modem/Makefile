
include $(TOPDIR)/rules.mk

PKG_VERSION:=1.0.4-20230408
PKG_RELEASE:=
PKG_MAINTAINER:=jjm2473 <jjm2473@gmail.com>

LUCI_TITLE:=Easy Access AP / Modem
LUCI_PKGARCH:=all

define Package/luci-app-ap-modem/conffiles
/etc/config/ap_modem
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
