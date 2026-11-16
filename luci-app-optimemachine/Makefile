include $(TOPDIR)/rules.mk
PKG_NAME:=luci-app-optimemachine
PKG_VERSION:=0.3.0-cg1
PKG_RELEASE:=1
include $(INCLUDE_DIR)/package.mk

define Package/luci-app-optimemachine
 SECTION:=admin
 CATEGORY:=System
 TITLE:=Legacy time machine UI retirement
 DEPENDS:=+changeguard
endef

define Build/Configure
endef
define Build/Compile
endef

define Package/luci-app-optimemachine/preinst
#!/bin/sh
IPKG_INSTROOT="$${IPKG_INSTROOT:-}" "$${IPKG_INSTROOT:-}/usr/libexec/changeguard-package" preinst
endef

define Package/luci-app-optimemachine/postinst
#!/bin/sh
IPKG_INSTROOT="$${IPKG_INSTROOT:-}" "$${IPKG_INSTROOT:-}/usr/libexec/changeguard-package" postinst
endef

define Package/luci-app-optimemachine/install
 $(INSTALL_DIR) $(1)/usr/share/changeguard
endef
$(eval $(call BuildPackage,luci-app-optimemachine))
