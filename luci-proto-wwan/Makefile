include $(TOPDIR)/rules.mk

PKG_NAME:=luci-proto-wwan
PKG_VERSION:=20151207
PKG_RELEASE:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)
PKG_BUILD_DEPENDS:=luci-base

include $(INCLUDE_DIR)/package.mk

define Package/luci-proto-wwan
	CATEGORY:=LuCI
	SUBMENU:=5. Protocols
	TITLE:=Support for WWAN/QMI/NCM
	MAINTAINER:=Cezary Jackiewicz <cezary@eko.one.pl>
	PKGARCH:=all
endef

define Build/Compile
endef

define Package/luci-proto-wwan/install
	$(CP) ./files/* $(1)
	$(FIND) $(1) -type f -name '*.lua' | while read src; do \
		if $(STAGING_DIR_HOST)/bin/lua $(STAGING_DIR_HOST)/bin/LuaSrcDiet \
			--noopt-binequiv -o "$$$$src.o" "$$$$src"; \
		then mv "$$$$src.o" "$$$$src"; fi; \
	done
endef

define Package/luci-proto-wwan/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
rm -f /var/luci-indexcache
}
exit 0
endef

$(eval $(call BuildPackage,luci-proto-wwan))
