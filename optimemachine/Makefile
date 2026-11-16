include $(TOPDIR)/rules.mk
PKG_NAME:=optimemachine
PKG_VERSION:=0.3.0-cg1
PKG_RELEASE:=1
include $(INCLUDE_DIR)/package.mk

define Package/optimemachine
 SECTION:=admin
 CATEGORY:=System
 TITLE:=changeguard legacy command compatibility
 DEPENDS:=+changeguard
endef

define Build/Configure
endef
define Build/Compile
endef

define Package/optimemachine/conffiles
/etc/config/optimemachine
endef

define Package/optimemachine/preinst
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

define Package/optimemachine/postinst
#!/bin/sh
IPKG_INSTROOT="$${IPKG_INSTROOT:-}" "$${IPKG_INSTROOT:-}/usr/libexec/changeguard-package" postinst
endef

define Package/optimemachine/prerm
#!/bin/sh
[ -n "$${IPKG_INSTROOT:-}" ] && exit 0
/usr/sbin/changeguard_bin maintenance-check >/dev/null
endef

define Package/optimemachine/install
 $(CP) ./files/* $(1)/
endef
$(eval $(call BuildPackage,optimemachine))
