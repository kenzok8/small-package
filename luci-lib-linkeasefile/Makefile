
include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI support for linkease file
LUCI_DEPENDS:=+linkease-common-bin
LUCI_PKGARCH:=all
PKG_VERSION:=2.1.70-r4
# PKG_RELEASE MUST be empty for luci.mk
PKG_RELEASE:=
LUCI_MINIFY_CSS:=0
LUCI_MINIFY_JS:=0

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature

# Hand shared UI files over from legacy monolithic luci-app-linkease packages.
LINKEASEFILE_GENERATED_CONTROL:=$(Package/luci-lib-linkeasefile/CONTROL)
define Package/luci-lib-linkeasefile/CONTROL
$(LINKEASEFILE_GENERATED_CONTROL)
Replaces: luci-app-linkease (<< 2.1.70-r4)
endef
