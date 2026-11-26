#
# Copyright (C) 2026 KaiPlus Contributors
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=kaiplus
PKG_VERSION:=1.0.25
PKG_RELEASE:=4

KAIPLUS_URL_FILE:=kaiplus-binary-$(PKG_VERSION).tar.gz
KAIPLUS_HASH:=13d31810ca6dd861515a683a1c7710868cba2895c515295eb064753eada1c628
KAIPLUS_DOWNLOAD:=$(KAIPLUS_URL_FILE)-$(KAIPLUS_HASH)
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0
STRIP:=true
RSTRIP:=:

include $(INCLUDE_DIR)/package.mk

define Download/kaiplus
	URL:=https://github.com/istoreos/istoreos-app-hub/releases/download/kaiplus-runtime-v$(PKG_VERSION)/
	URL_FILE:=$(KAIPLUS_URL_FILE)
	FILE:=$(KAIPLUS_DOWNLOAD)
	HASH:=$(KAIPLUS_HASH)
endef

define Package/kaiplus-sandbox
	SECTION:=net
	CATEGORY:=System
	TITLE:=KaiPlus optional Linux sandbox backend
	DEPENDS:=@(x86_64||aarch64) +kaiplus +bubblewrap
endef

define Package/kaiplus-sandbox/description
  Optional backend for explicitly configured sandbox.bash="enforce".
  KAIPlus native device management does not require bubblewrap.
  Installation never rewrites the user's execution or approval preferences.
endef

define Package/kaiplus-sandbox/install
	$(INSTALL_DIR) $(1)/usr/share/kaiplus
	$(INSTALL_DATA) ./files/sandbox-backend.txt $(1)/usr/share/kaiplus/sandbox-backend.txt
endef

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=System
	SUBMENU:=
	TITLE:=KaiPlus
	URL:=https://github.com/linkease/istore-packages
	DEPENDS:=@(x86_64||aarch64) +linkease-app-entry +changeguard
	# Build matrix: OpenWrt 21.02 OPKG uses -N; 25.12 APK uses -rN.
	EXTRA_DEPENDS:=changeguard (>=0.3.5-$(if $(CONFIG_USE_APK),r)4), luci-lib-linkeaseauth (>=1.2.1-r5)
endef

define Package/$(PKG_NAME)/description
  KaiPlus is a single-process AI workspace and session service.
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/kaiplus
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
# Compatibility entry for desktops which only scan the old directory.
root="$${IPKG_INSTROOT:-}"
legacy="$${root}/usr/share/linkeasefull/desktop-apps.d/00-kaiplus-plugin.json"
if [ ! -e "$${legacy}" ] && [ ! -L "$${legacy}" ]; then
	mkdir -p "$${legacy%/*}" || printf '%s\n' 'kaiplus: unable to create compatibility app directory.' >&2
	ln -s /usr/share/kaiplus/kaiplus-plugin.json "$${legacy}" 2>/dev/null || \
		printf '%s\n' 'kaiplus: unable to create compatibility app entry.' >&2
fi
if [ -z "$${IPKG_INSTROOT}" ]; then
	for option in port listen_mode external_port_enabled bind_addr; do
		uci -q delete "kaiplus.@kaiplus[0].$${option}" || true
	done
	uci -q commit kaiplus || printf '%s\n' 'kaiplus: unable to save migrated settings.' >&2
	if pidof kaiplus kaiplus_bin >/dev/null 2>&1; then
		/etc/init.d/kaiplus restart || printf '%s\n' 'kaiplus: unable to restart service; restart it manually.' >&2
	fi
fi
exit 0
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh
root="$${IPKG_INSTROOT:-}"
for directory in /usr/share/linkease/apps.d /usr/share/linkeasefull/desktop-apps.d; do
	registration="$${root}$${directory}/00-kaiplus-plugin.json"
	if [ "$$(readlink "$${registration}" 2>/dev/null)" = "/usr/share/kaiplus/kaiplus-plugin.json" ]; then
		rm -f "$${registration}"
	fi
done
rmdir "$${root}/usr/share/linkeasefull/desktop-apps.d" 2>/dev/null || true
exit 0
endef

define Build/Prepare
	$(INSTALL_DIR) $(PKG_BUILD_DIR)
	tar -xzf $(DL_DIR)/$(KAIPLUS_DOWNLOAD) -C $(PKG_BUILD_DIR) --strip-components=1
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/usr/share/kaiplus $(1)/usr/share/linkease/apps.d $(1)/usr/share/rpcd/acl.d $(1)/etc/init.d $(1)/etc/config
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/kaiplus.$(ARCH) $(1)/usr/sbin/kaiplus_bin
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/kaiplus-web.zip $(1)/usr/share/kaiplus/kaiplus-web.zip
	ln -sf kaiplus_bin $(1)/usr/sbin/kaiplus
	ln -sf /www/luci-static/resources/app-icons/kaiplus.png $(1)/usr/share/kaiplus/logo.png
	$(INSTALL_DATA) ./files/kaiplus-plugin.json $(1)/usr/share/kaiplus/kaiplus-plugin.json
	$(INSTALL_DATA) ./files/kaiplus.json $(1)/usr/share/rpcd/acl.d/kaiplus.json
	ln -sf /usr/share/kaiplus/kaiplus-plugin.json $(1)/usr/share/linkease/apps.d/00-kaiplus-plugin.json
	$(INSTALL_BIN) ./files/kaiplus.init $(1)/etc/init.d/kaiplus
	$(INSTALL_CONF) ./files/kaiplus.config $(1)/etc/config/kaiplus
endef

$(eval $(call Download,kaiplus))
$(eval $(call BuildPackage,$(PKG_NAME)))
$(eval $(call BuildPackage,kaiplus-sandbox))
