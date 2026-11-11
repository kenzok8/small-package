#
# Copyright (C) 2026 iStoreOS
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-linkeasefull-embed
PKG_VERSION:=1.2.0-r3
PKG_RELEASE:=

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=LinkEaseFull LuCI desktop embed
	DEPENDS:=+linkeasefull +luci-base +luci-theme-istorenas
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
  Register OpenWrt LuCI as a LinkEaseFull desktop module and provide embedded-mode assets.
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
# Compatibility entry for desktops which only scan the old directory.
root="$${IPKG_INSTROOT:-}"
legacy="$${root}/usr/share/linkeasefull/desktop-apps.d/15-openwrt-luci.json"
if [ ! -e "$${legacy}" ] && [ ! -L "$${legacy}" ]; then
	mkdir -p "$${legacy%/*}"
	ln -s /usr/share/linkeasefull/openwrt-luci/openwrt-luci.json "$${legacy}" || exit $$?
fi
exit 0
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh
set -e
root="$${IPKG_INSTROOT:-}"
for directory in /usr/share/linkease/apps.d /usr/share/linkeasefull/desktop-apps.d; do
	registration="$${root}$${directory}/15-openwrt-luci.json"
	if [ "$$(readlink "$${registration}" 2>/dev/null)" = "/usr/share/linkeasefull/openwrt-luci/openwrt-luci.json" ]; then
		rm -f "$${registration}"
	fi
done
rmdir "$${root}/usr/share/linkeasefull/desktop-apps.d" 2>/dev/null || true
exit 0
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/share/linkeasefull/openwrt-luci $(1)/usr/share/linkease/apps.d
	$(INSTALL_DIR) $(1)/www/luci-static/linkeasefull-embed
	$(INSTALL_DATA) ./files/openwrt-luci/openwrt-luci.json $(1)/usr/share/linkeasefull/openwrt-luci/openwrt-luci.json
	$(INSTALL_DATA) ./files/openwrt-luci/openwrt.svg $(1)/usr/share/linkeasefull/openwrt-luci/openwrt.svg
	$(INSTALL_DATA) ./files/www/embed.css $(1)/www/luci-static/linkeasefull-embed/embed.css
	$(INSTALL_DATA) ./files/www/embed-prelude.js $(1)/www/luci-static/linkeasefull-embed/embed-prelude.js
	ln -sf /usr/share/linkeasefull/openwrt-luci/openwrt-luci.json $(1)/usr/share/linkease/apps.d/15-openwrt-luci.json
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
