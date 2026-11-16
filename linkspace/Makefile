include $(TOPDIR)/rules.mk
PKG_NAME:=linkspace
PKG_VERSION:=0.3.1
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
if [ -x /usr/libexec/changeguard-package ]; then /usr/libexec/changeguard-package preinst; exit $$?; fi
if [ -x /usr/sbin/optimemachine_bin ] && [ -f /etc/optimemachine/config.json ]; then
 /usr/sbin/optimemachine_bin maintenance-check >/dev/null || exit 1
 if /etc/init.d/optimemachine enabled; then touch /var/run/optimemachine-package-enable; fi
 if [ -S /var/run/optimemachine.sock ]; then touch /var/run/optimemachine-package-restart; /etc/init.d/optimemachine stop || exit 1; fi
 /usr/sbin/optimemachine_bin maintenance-check >/dev/null || { /etc/init.d/optimemachine start; exit 1; }
fi
exit 0
endef
define Package/linkspace/prerm
#!/bin/sh
[ -n "$${IPKG_INSTROOT:-}" ] && exit 0
if [ -x /usr/libexec/changeguard-package ]; then /usr/libexec/changeguard-package preinst; exit $$?; fi
if [ -x /usr/sbin/optimemachine_bin ] && [ -f /etc/optimemachine/config.json ]; then
 /usr/sbin/optimemachine_bin maintenance-check >/dev/null || exit 1
 if [ -S /var/run/optimemachine.sock ]; then touch /var/run/optimemachine-package-restart; /etc/init.d/optimemachine stop || exit 1; fi
 /usr/sbin/optimemachine_bin maintenance-check >/dev/null || { /etc/init.d/optimemachine start; exit 1; }
fi
exit 0
endef
define Package/linkspace/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT:-}" ] && exit 0
if [ -x /usr/libexec/changeguard-package ]; then /usr/libexec/changeguard-package postinst; exit $$?; fi
if [ -x /usr/sbin/optimemachine_bin ] && [ -f /etc/optimemachine/config.json ]; then
 if ! /usr/sbin/optimemachine_bin capabilities | grep -q '"backendDescriptorV2":true'; then
  logger -t optimemachine "Linkspace updated; complete coordinated optimemachine upgrade before restarting protection"
  exit 0
 fi
 /usr/sbin/optimemachine_bin sync-backend >/dev/null || exit 1
 if [ -f /var/run/optimemachine-package-enable ]; then /etc/init.d/optimemachine enable; rm -f /var/run/optimemachine-package-enable; fi
 if [ -f /var/run/optimemachine-package-restart ]; then /etc/init.d/optimemachine start || exit 1; rm -f /var/run/optimemachine-package-restart; fi
fi
exit 0
endef

define Package/linkspace/install
	$(INSTALL_DIR) $(1)/usr/bin $(1)/usr/share/linkspace
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/linkspace $(1)/usr/bin/linkspace
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/dependency.json $(1)/usr/share/linkspace/dependency.json
endef
$(eval $(call BuildPackage,linkspace))
