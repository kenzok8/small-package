include $(TOPDIR)/rules.mk
PKG_NAME:=changeguard
PKG_VERSION:=0.3.5
PKG_RELEASE:=4
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
 DEPENDS:=@(x86_64||aarch64) +linkspace +block-mount +ucode
 # Build matrix: OpenWrt 21.02 OPKG uses -N; 25.12 APK uses -rN.
 EXTRA_DEPENDS:=linkspace (>=0.3.3-$(if $(CONFIG_USE_APK),r)3)
endef

define Build/Configure
endef
define Build/Compile
endef

define Package/changeguard/preinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT:-}" ] && exit 0
if pidof changeguard_bin >/dev/null 2>&1; then
	printf '%s\n' 'ChangeGuard stopped for upgrade; any active protection has failed.' >&2
fi
ubus call service delete '{"name":"changeguard"}' >/dev/null 2>&1 || true
killall changeguard_bin >/dev/null 2>&1 || true
exit 0
endef

define Package/changeguard/postinst
#!/bin/sh
IPKG_INSTROOT="$${IPKG_INSTROOT:-}" "$${IPKG_INSTROOT:-}/usr/libexec/changeguard-package" postinst || \
	printf '%s\n' 'changeguard: post-install setup failed; package installation will continue.' >&2
exit 0
endef

define Package/changeguard/prerm
#!/bin/sh
IPKG_INSTROOT="$${IPKG_INSTROOT:-}" "$${IPKG_INSTROOT:-}/usr/libexec/changeguard-package" prerm || \
	printf '%s\n' 'changeguard: pre-remove cleanup failed; package removal will continue.' >&2
exit 0
endef

define Package/changeguard/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/changeguard_bin $(1)/usr/sbin/changeguard_bin
	$(CP) ./files/* $(1)/
endef
$(eval $(call BuildPackage,changeguard))
