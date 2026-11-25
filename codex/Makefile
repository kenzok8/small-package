include $(TOPDIR)/rules.mk

PKG_NAME:=codex
PKG_VERSION:=0.172.0
PKG_RELEASE:=3
PKG_LICENSE:=Apache-2.0
PKG_MAINTAINER:=LinkEase

include $(INCLUDE_DIR)/package.mk

define Package/codex
	SECTION:=utils
	CATEGORY:=Utilities
	TITLE:=OpenAI Codex CLI for iStoreOS
	DEPENDS:=@(x86_64||aarch64) +mise-runtime +git +git-http +ttyd +jsonfilter +linkease-app-entry
	EXTRA_DEPENDS:=mise-runtime (>=0.1.1-$(if $(CONFIG_USE_APK),r)2), luci-lib-linkeaseauth (>=1.2.1-r5)
	URL:=https://developers.openai.com/codex/cli
endef

define Package/codex/description
  Installs and runs a fixed OpenAI Codex CLI release with mise-runtime.
endef

define Package/codex/conffiles
/etc/config/codex
endef

define Package/codex/postinst
#!/bin/sh
root="$${IPKG_INSTROOT:-}"
if [ -z "$${root}" ] && ! id codex >/dev/null 2>&1; then
	. /lib/functions.sh
	gid="$$(group_add_next codex)" || exit $$?
	user_add codex "" "$${gid}" "Codex CLI" /var/empty /bin/false || exit $$?
fi
legacy="$${root}/usr/share/linkeasefull/desktop-apps.d/35-codex.json"
if [ ! -e "$${legacy}" ] && [ ! -L "$${legacy}" ]; then
	mkdir -p "$${legacy%/*}"
	ln -s /usr/share/codex/codex-plugin.json "$${legacy}" || exit $$?
fi
exit 0
endef

define Package/codex/prerm
#!/bin/sh
[ -n "$${IPKG_INSTROOT:-}" ] || /etc/init.d/codex stop >/dev/null 2>&1 || true
root="$${IPKG_INSTROOT:-}"
for directory in /usr/share/linkease/apps.d /usr/share/linkeasefull/desktop-apps.d; do
	registration="$${root}$${directory}/35-codex.json"
	if [ "$$(readlink "$${registration}" 2>/dev/null)" = "/usr/share/codex/codex-plugin.json" ]; then
		rm -f "$${registration}"
	fi
done
rmdir "$${root}/usr/share/linkeasefull/desktop-apps.d" 2>/dev/null || true
exit 0
endef

define Build/Compile
endef

define Package/codex/install
	$(INSTALL_DIR) $(1)/usr/bin $(1)/usr/libexec $(1)/usr/share/codex/www $(1)/usr/share/coding-agents.d
	$(INSTALL_DIR) $(1)/usr/share/linkease/apps.d $(1)/etc/init.d $(1)/etc/config $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/codex $(1)/usr/bin/codex
	$(INSTALL_BIN) ./files/codex-runtime $(1)/usr/libexec/codex-runtime
	$(INSTALL_DATA) ./files/runtime-cli.lua $(1)/usr/share/codex/runtime-cli.lua
	$(INSTALL_DATA) ./files/codex-runtime.lua $(1)/usr/share/codex/codex-runtime.lua
	$(INSTALL_DATA) ./files/codex-package.lua $(1)/usr/share/codex/codex-package.lua
	$(INSTALL_BIN) ./files/codex.init $(1)/etc/init.d/codex
	$(INSTALL_BIN) ./files/codex.uci-default $(1)/etc/uci-defaults/90-codex
	$(INSTALL_CONF) ./files/codex.config $(1)/etc/config/codex
	$(INSTALL_DATA) ./files/codex-plugin.json $(1)/usr/share/codex/codex-plugin.json
	$(INSTALL_DATA) ./files/codex-agent.json $(1)/usr/share/coding-agents.d/codex.json
	$(INSTALL_DATA) ./files/logo.svg $(1)/usr/share/codex/www/logo.svg
	ln -sf /usr/share/codex/codex-plugin.json $(1)/usr/share/linkease/apps.d/35-codex.json
endef

$(eval $(call BuildPackage,codex))
