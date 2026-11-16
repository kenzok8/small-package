include $(TOPDIR)/rules.mk
PKG_NAME:=changeguard
PKG_VERSION:=0.3.1
PKG_RELEASE:=1
include ./release.mk
PKG_SOURCE:=changeguard-$(PKG_VERSION)-$(ARCH).tar.gz
PKG_SOURCE_URL:=https://github.com/istoreos/istoreos-app-hub/releases/download/changeguard-runtime-v$(PKG_VERSION)/
PKG_HASH:=$(CHANGEGUARD_HASH_$(ARCH))
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
STRIP:=true
RSTRIP:=:
include $(INCLUDE_DIR)/package.mk

define Package/changeguard
 SECTION:=admin
 CATEGORY:=System
 TITLE:=Device change protection CLI
 DEPENDS:=@(x86_64||aarch64) +linkspace +block-mount
endef

define Build/Configure
endef
define Build/Compile
endef

define Package/changeguard/preinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT:-}" ] && exit 0
if [ -x /usr/libexec/changeguard-package ]; then /usr/libexec/changeguard-package preinst; exit $$?; fi
if [ -x /usr/sbin/optimemachine_bin ] && [ -f /etc/optimemachine/config.json ]; then
 /usr/sbin/optimemachine_bin maintenance-check >/dev/null || exit 1
 touch /var/run/changeguard-package-upgrade
 if /etc/init.d/optimemachine enabled; then touch /var/run/optimemachine-package-enable; fi
 if /usr/sbin/optimemachine_bin status --config /etc/optimemachine/config.json >/dev/null 2>&1; then
  touch /var/run/optimemachine-package-restart
  /etc/init.d/optimemachine stop || exit 1
 fi
 /usr/sbin/optimemachine_bin maintenance-check --config /etc/optimemachine/config.json >/dev/null || exit 1
fi
exit 0
endef

define Package/changeguard/postinst
#!/bin/sh
IPKG_INSTROOT="$${IPKG_INSTROOT:-}" "$${IPKG_INSTROOT:-}/usr/libexec/changeguard-package" postinst
endef

define Package/changeguard/prerm
#!/bin/sh
IPKG_INSTROOT="$${IPKG_INSTROOT:-}" "$${IPKG_INSTROOT:-}/usr/libexec/changeguard-package" prerm
endef

define Package/changeguard/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/changeguard_bin $(1)/usr/sbin/changeguard_bin
	$(CP) ./files/* $(1)/
endef
$(eval $(call BuildPackage,changeguard))
