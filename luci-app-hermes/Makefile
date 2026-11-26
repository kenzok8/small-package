
include $(TOPDIR)/rules.mk

PKG_VERSION:=1.0.1
PKG_RELEASE:=1

LUCI_TITLE:=LuCI support for Hermes
LUCI_PKGARCH:=all
LUCI_DEPENDS:=@(x86_64||aarch64) +luci-base +luci-compat +luci-lib-taskd +curl +ca-bundle +tar +jsonfilter +mise-runtime +coreutils-timeout +coreutils-stat +libstdcpp +libatomic
LUCI_EXTRA_DEPENDS:=mise-runtime (>=0.1.1-$(if $(CONFIG_USE_APK),r)4)

define Package/luci-app-hermes/conffiles
/etc/config/hermes
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
