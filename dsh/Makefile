#
# Copyright (C) 2026 LinkEase Contributors
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=dsh
PKG_VERSION:=0.2.1
PKG_RELEASE:=3
PKGARCH:=all

include $(INCLUDE_DIR)/package.mk

define Package/dsh
	SECTION:=utils
	CATEGORY:=Utilities
	TITLE:=DeepSeek Harness container runtime integration
	URL:=https://github.com/deepseek-ai/deepseek-harness
	DEPENDS:=@(x86_64||aarch64) +docker +dockerd +dockerd +ca-bundle +linkease-app-entry
endef

define Package/dsh/description
  Runs a pinned DeepSeek Harness container on a dedicated authenticated Web
  port. DSH data and workspaces remain on persistent storage.
endef

define Package/dsh/conffiles
/etc/config/dsh
endef

define Package/dsh/postinst
#!/bin/sh
root="$${IPKG_INSTROOT:-}"
legacy="$${root}/usr/share/linkeasefull/desktop-apps.d/39-dsh.json"
if [ ! -e "$${legacy}" ] && [ ! -L "$${legacy}" ]; then
	mkdir -p "$${legacy%/*}"
	ln -s /usr/share/dsh/dsh-plugin.json "$${legacy}" || exit $$?
fi
exit 0
endef

define Package/dsh/prerm
#!/bin/sh
if [ -z "$${IPKG_INSTROOT:-}" ]; then
	/usr/libexec/istorec/dsh.sh rm 2>/dev/null || true
fi
root="$${IPKG_INSTROOT:-}"
for directory in /usr/share/linkease/apps.d /usr/share/linkeasefull/desktop-apps.d; do
	registration="$${root}$${directory}/39-dsh.json"
	if [ "$$(readlink "$${registration}" 2>/dev/null)" = "/usr/share/dsh/dsh-plugin.json" ]; then
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

define Package/dsh/install
	$(INSTALL_DIR) $(1)/etc/config $(1)/etc/init.d $(1)/usr/libexec/istorec $(1)/usr/share/dsh/www $(1)/usr/share/linkease/apps.d
	$(INSTALL_CONF) ./files/dsh.config $(1)/etc/config/dsh
	$(INSTALL_BIN) ./files/dsh.init $(1)/etc/init.d/dsh
	$(INSTALL_BIN) ./files/dsh.sh $(1)/usr/libexec/istorec/dsh.sh
	$(INSTALL_DATA) ./files/advanced.Caddyfile $(1)/usr/share/dsh/advanced.Caddyfile
	$(INSTALL_DATA) ./files/dsh-plugin.json $(1)/usr/share/dsh/dsh-plugin.json
	$(INSTALL_DATA) ./files/logo.svg $(1)/usr/share/dsh/www/logo.svg
	ln -sf /usr/share/dsh/dsh-plugin.json $(1)/usr/share/linkease/apps.d/39-dsh.json
endef

$(eval $(call BuildPackage,dsh))
