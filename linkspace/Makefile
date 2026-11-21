include $(TOPDIR)/rules.mk
PKG_NAME:=linkspace
PKG_VERSION:=0.3.3
PKG_RELEASE:=1
include ./release.mk
PKG_SOURCE:=linkspace-$(PKG_VERSION)-$(ARCH).tar.gz
PKG_SOURCE_URL:=https://github.com/istoreos/istoreos-app-hub/releases/download/linkspace-runtime-v$(PKG_VERSION)/
PKG_HASH:=$(LINKSPACE_HASH_$(ARCH))
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_BUILD_PARALLEL:=1
STRIP:=true
RSTRIP:=:
include $(INCLUDE_DIR)/package.mk

define Package/linkspace
 SECTION:=admin
 CATEGORY:=System
 TITLE:=Linkspace backup engine
 DEPENDS:=@(x86_64||aarch64)
endef

define Build/Configure
endef
define Build/Compile
endef

define Package/linkspace/preinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT:-}" ] && exit 0
if [ -x /usr/libexec/changeguard-package ]; then exec /usr/libexec/changeguard-package preinst; fi
exit 0
endef

define Package/linkspace/prerm
#!/bin/sh
[ -n "$${IPKG_INSTROOT:-}" ] && exit 0
if [ -x /usr/libexec/changeguard-package ]; then exec /usr/libexec/changeguard-package preinst; fi
exit 0
endef

define Package/linkspace/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT:-}" ] && exit 0
if [ -x /usr/libexec/changeguard-package ]; then exec /usr/libexec/changeguard-package postinst; fi
exit 0
endef

define Package/linkspace/install
	$(INSTALL_DIR) $(1)/usr/bin $(1)/usr/share/linkspace
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/linkspace $(1)/usr/bin/linkspace
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/dependency.json $(1)/usr/share/linkspace/dependency.json
endef
$(eval $(call BuildPackage,linkspace))
