include $(TOPDIR)/rules.mk

PKG_NAME:=claude-code
PKG_VERSION:=2.1.326
PKG_RELEASE:=4
PKG_LICENSE:=Proprietary
PKG_MAINTAINER:=LinkEase

include $(INCLUDE_DIR)/package.mk

define Package/claude-code
	SECTION:=utils
	CATEGORY:=Utilities
	TITLE:=Anthropic Claude Code CLI for iStoreOS
	DEPENDS:=@(x86_64||aarch64) +mise-runtime +git +git-http +ttyd +jsonfilter +linkease-app-entry
	EXTRA_DEPENDS:=mise-runtime (>=0.1.1-$(if $(CONFIG_USE_APK),r)2), luci-lib-linkeaseauth (>=1.2.1-r5)
	URL:=https://code.claude.com/docs/
endef

define Package/claude-code/description
  Installs and runs a fixed Anthropic Claude Code CLI release with mise-runtime.
endef

define Package/claude-code/conffiles
/etc/config/claude
endef

define Package/claude-code/postinst
#!/bin/sh
root="$${IPKG_INSTROOT:-}"
if [ -z "$${root}" ] && ! id claude >/dev/null 2>&1; then
	. /lib/functions.sh
	gid="$$(group_add_next claude)" || exit $$?
	user_add claude "" "$${gid}" "Claude Code CLI" /var/empty /bin/false || exit $$?
fi
legacy="$${root}/usr/share/linkeasefull/desktop-apps.d/36-claude-code.json"
if [ ! -e "$${legacy}" ] && [ ! -L "$${legacy}" ]; then
	mkdir -p "$${legacy%/*}"
	ln -s /usr/share/claude/claude-plugin.json "$${legacy}" || exit $$?
fi
exit 0
endef

define Package/claude-code/prerm
#!/bin/sh
[ -n "$${IPKG_INSTROOT:-}" ] || /etc/init.d/claude stop >/dev/null 2>&1 || true
root="$${IPKG_INSTROOT:-}"
for directory in /usr/share/linkease/apps.d /usr/share/linkeasefull/desktop-apps.d; do
	registration="$${root}$${directory}/36-claude-code.json"
	if [ "$$(readlink "$${registration}" 2>/dev/null)" = "/usr/share/claude/claude-plugin.json" ]; then
		rm -f "$${registration}"
	fi
done
rmdir "$${root}/usr/share/linkeasefull/desktop-apps.d" 2>/dev/null || true
exit 0
endef

define Build/Compile
endef

define Package/claude-code/install
	$(INSTALL_DIR) $(1)/usr/bin $(1)/usr/libexec $(1)/usr/share/claude/www $(1)/usr/share/coding-agents.d
	$(INSTALL_DIR) $(1)/usr/share/linkease/apps.d $(1)/etc/init.d $(1)/etc/config $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/claude $(1)/usr/bin/claude
	$(INSTALL_BIN) ./files/claude-runtime $(1)/usr/libexec/claude-runtime
	$(INSTALL_DATA) ./files/runtime-cli.lua $(1)/usr/share/claude/runtime-cli.lua
	$(INSTALL_DATA) ./files/claude-runtime.lua $(1)/usr/share/claude/claude-runtime.lua
	$(INSTALL_DATA) ./files/claude-package.lua $(1)/usr/share/claude/claude-package.lua
	$(INSTALL_BIN) ./files/claude.init $(1)/etc/init.d/claude
	$(INSTALL_BIN) ./files/claude.uci-default $(1)/etc/uci-defaults/90-claude
	$(INSTALL_CONF) ./files/claude.config $(1)/etc/config/claude
	$(INSTALL_DATA) ./files/claude-plugin.json $(1)/usr/share/claude/claude-plugin.json
	$(INSTALL_DATA) ./files/claude-agent.json $(1)/usr/share/coding-agents.d/claude-code.json
	$(INSTALL_DATA) ./files/logo.svg $(1)/usr/share/claude/www/logo.svg
	ln -sf /usr/share/claude/claude-plugin.json $(1)/usr/share/linkease/apps.d/36-claude-code.json
endef

$(eval $(call BuildPackage,claude-code))
