include $(TOPDIR)/rules.mk

PKG_NAME:=linkease-runtime-transition
PKG_VERSION:=1.7.6
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=Web Servers/Proxies
	TITLE:=LinkEase split-runtime transition contract
	DEPENDS:=@(arm||x86_64||aarch64) +linkease +luci-lib-linkeasefile
	EXTRA_DEPENDS:=linkease (>=1.7.6~0), luci-lib-linkeasefile (>=2.1.70-r4)
	PKGARCH:=all
	URL:=https://www.linkease.com/
endef

define Package/$(PKG_NAME)/description
  Forces legacy LinkEase installations onto the split-safe runtime and LuCI
  ownership generation without exposing version expressions to app-meta hooks.
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/share/linkease
	$(INSTALL_DATA) ./files/runtime-generation $(1)/usr/share/linkease/runtime-generation
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
