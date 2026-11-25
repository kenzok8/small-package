include $(TOPDIR)/rules.mk

PKG_NAME:=opencode
PKG_VERSION:=2.4.1
PKG_RELEASE:=3
PKG_LICENSE:=MIT
PKG_MAINTAINER:=LinkEase

include $(INCLUDE_DIR)/package.mk

define Package/opencode
	SECTION:=utils
	CATEGORY:=Utilities
	TITLE:=OpenCode CLI for iStoreOS
	DEPENDS:=@(x86_64||aarch64) +mise-runtime +git +git-http +ttyd +jsonfilter +linkease-app-entry
	EXTRA_DEPENDS:=mise-runtime (>=0.1.1-$(if $(CONFIG_USE_APK),r)2), luci-lib-linkeaseauth (>=1.2.1-r5)
	URL:=https://opencode.ai/docs/
endef

define Package/opencode/description
  Installs and runs a fixed OpenCode CLI release with mise-runtime.
endef

define Package/opencode/conffiles
/etc/config/opencode
endef

define Package/opencode/postinst
#!/bin/sh
root="$${IPKG_INSTROOT:-}"
if [ -z "$${root}" ] && ! id opencode >/dev/null 2>&1; then
	. /lib/functions.sh
	gid="$$(group_add_next opencode)" || exit $$?
	user_add opencode "" "$${gid}" "OpenCode CLI" /var/empty /bin/false || exit $$?
fi
legacy="$${root}/usr/share/linkeasefull/desktop-apps.d/37-opencode.json"
if [ ! -e "$${legacy}" ] && [ ! -L "$${legacy}" ]; then
	mkdir -p "$${legacy%/*}"
	ln -s /usr/share/opencode/opencode-plugin.json "$${legacy}" || exit $$?
fi
exit 0
endef

define Package/opencode/prerm
#!/bin/sh
[ -n "$${IPKG_INSTROOT:-}" ] || /etc/init.d/opencode stop >/dev/null 2>&1 || true
root="$${IPKG_INSTROOT:-}"
for directory in /usr/share/linkease/apps.d /usr/share/linkeasefull/desktop-apps.d; do
	registration="$${root}$${directory}/37-opencode.json"
	if [ "$$(readlink "$${registration}" 2>/dev/null)" = "/usr/share/opencode/opencode-plugin.json" ]; then
		rm -f "$${registration}"
	fi
done
rmdir "$${root}/usr/share/linkeasefull/desktop-apps.d" 2>/dev/null || true
exit 0
endef

define Build/Compile
endef

define Package/opencode/install
	$(INSTALL_DIR) $(1)/usr/bin $(1)/usr/libexec $(1)/usr/share/opencode/www $(1)/usr/share/coding-agents.d
	$(INSTALL_DIR) $(1)/usr/share/linkease/apps.d $(1)/etc/init.d $(1)/etc/config $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/opencode $(1)/usr/bin/opencode
	$(INSTALL_BIN) ./files/opencode-runtime $(1)/usr/libexec/opencode-runtime
	$(INSTALL_DATA) ./files/runtime-cli.lua $(1)/usr/share/opencode/runtime-cli.lua
	$(INSTALL_DATA) ./files/opencode-runtime.lua $(1)/usr/share/opencode/opencode-runtime.lua
	$(INSTALL_DATA) ./files/opencode-package.lua $(1)/usr/share/opencode/opencode-package.lua
	$(INSTALL_BIN) ./files/opencode.init $(1)/etc/init.d/opencode
	$(INSTALL_BIN) ./files/opencode.uci-default $(1)/etc/uci-defaults/90-opencode
	$(INSTALL_CONF) ./files/opencode.config $(1)/etc/config/opencode
	$(INSTALL_DATA) ./files/opencode-plugin.json $(1)/usr/share/opencode/opencode-plugin.json
	$(INSTALL_DATA) ./files/opencode-agent.json $(1)/usr/share/coding-agents.d/opencode.json
	$(INSTALL_DATA) ./files/logo.svg $(1)/usr/share/opencode/www/logo.svg
	ln -sf /usr/share/opencode/opencode-plugin.json $(1)/usr/share/linkease/apps.d/37-opencode.json
endef

$(eval $(call BuildPackage,opencode))
