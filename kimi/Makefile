include $(TOPDIR)/rules.mk

PKG_NAME:=kimi
PKG_VERSION:=2.7.3
PKG_RELEASE:=3
PKG_LICENSE:=MIT
PKG_MAINTAINER:=LinkEase

include $(INCLUDE_DIR)/package.mk

define Package/kimi
	SECTION:=utils
	CATEGORY:=Utilities
	TITLE:=Moonshot AI Kimi Code CLI for iStoreOS
	DEPENDS:=@(x86_64||aarch64) +mise-runtime +git +git-http +ttyd +jsonfilter +linkease-app-entry
	EXTRA_DEPENDS:=mise-runtime (>=0.1.1-$(if $(CONFIG_USE_APK),r)2), luci-lib-linkeaseauth (>=1.2.1-r5)
	URL:=https://www.kimi.com/code/docs/en/
endef

define Package/kimi/description
  Installs and runs a fixed Moonshot AI Kimi Code CLI release with mise-runtime.
endef

define Package/kimi/conffiles
/etc/config/kimi
endef

define Package/kimi/postinst
#!/bin/sh
root="$${IPKG_INSTROOT:-}"
if [ -z "$${root}" ] && ! id kimi >/dev/null 2>&1; then
	. /lib/functions.sh
	gid="$$(group_add_next kimi)" || exit $$?
	user_add kimi "" "$${gid}" "Kimi Code CLI" /var/empty /bin/false || exit $$?
fi
legacy="$${root}/usr/share/linkeasefull/desktop-apps.d/38-kimi.json"
if [ ! -e "$${legacy}" ] && [ ! -L "$${legacy}" ]; then
	mkdir -p "$${legacy%/*}"
	ln -s /usr/share/kimi/kimi-plugin.json "$${legacy}" || exit $$?
fi
exit 0
endef

define Package/kimi/prerm
#!/bin/sh
[ -n "$${IPKG_INSTROOT:-}" ] || /etc/init.d/kimi stop >/dev/null 2>&1 || true
root="$${IPKG_INSTROOT:-}"
for directory in /usr/share/linkease/apps.d /usr/share/linkeasefull/desktop-apps.d; do
	registration="$${root}$${directory}/38-kimi.json"
	if [ "$$(readlink "$${registration}" 2>/dev/null)" = "/usr/share/kimi/kimi-plugin.json" ]; then
		rm -f "$${registration}"
	fi
done
rmdir "$${root}/usr/share/linkeasefull/desktop-apps.d" 2>/dev/null || true
exit 0
endef

define Build/Compile
endef

define Package/kimi/install
	$(INSTALL_DIR) $(1)/usr/bin $(1)/usr/libexec $(1)/usr/share/kimi/www $(1)/usr/share/coding-agents.d
	$(INSTALL_DIR) $(1)/usr/share/linkease/apps.d $(1)/etc/init.d $(1)/etc/config $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/kimi $(1)/usr/bin/kimi
	$(INSTALL_BIN) ./files/kimi-runtime $(1)/usr/libexec/kimi-runtime
	$(INSTALL_DATA) ./files/runtime-cli.lua $(1)/usr/share/kimi/runtime-cli.lua
	$(INSTALL_DATA) ./files/kimi-runtime.lua $(1)/usr/share/kimi/kimi-runtime.lua
	$(INSTALL_DATA) ./files/kimi-package.lua $(1)/usr/share/kimi/kimi-package.lua
	$(INSTALL_BIN) ./files/kimi.init $(1)/etc/init.d/kimi
	$(INSTALL_BIN) ./files/kimi.uci-default $(1)/etc/uci-defaults/90-kimi
	$(INSTALL_CONF) ./files/kimi.config $(1)/etc/config/kimi
	$(INSTALL_DATA) ./files/kimi-plugin.json $(1)/usr/share/kimi/kimi-plugin.json
	$(INSTALL_DATA) ./files/kimi-agent.json $(1)/usr/share/coding-agents.d/kimi.json
	$(INSTALL_DATA) ./files/logo.svg $(1)/usr/share/kimi/www/logo.svg
	ln -sf /usr/share/kimi/kimi-plugin.json $(1)/usr/share/linkease/apps.d/38-kimi.json
endef

$(eval $(call BuildPackage,kimi))
