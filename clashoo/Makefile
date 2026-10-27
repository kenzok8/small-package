include $(TOPDIR)/rules.mk

PKG_NAME:=clashoo
PKG_UPSTREAM_VERSION:=1.19.33
PKG_UPSTREAM_TAG:=v$(PKG_UPSTREAM_VERSION)
PKG_SHORT_SHA:=3f27ef3

PKG_VERSION:=2026.10.25.$(PKG_UPSTREAM_VERSION)
PKG_RELEASE:=5

PKG_SOURCE:=$(PKG_NAME)-stable-$(PKG_UPSTREAM_TAG)-$(PKG_SHORT_SHA).tar.gz
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-stable-$(PKG_UPSTREAM_TAG)-$(PKG_SHORT_SHA)
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_SOURCE_SUBDIR)
PKG_SOURCE_URL:=https://github.com/kenzok8/openwrt-clashoo/releases/download/mihomo-src
PKG_SOURCE_VERSION:=3f27ef39f8c96bbfbc8b0b9bb10f5c9ef60149d8
PKG_HASH:=1ef7a4087f3805bd2624a940e2e43a0bc23719a25465c9f503aa6c11572f1321
PKG_BUILD_VERSION:=$(PKG_UPSTREAM_TAG)

PKG_LICENSE:=GPL3.0+
PKG_MAINTAINER:=kenzok8

PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1
PKG_BUILD_FLAGS:=no-mips16

PKG_BUILD_TIME:=$(shell date -u -Iseconds)

GO_PKG:=github.com/metacubex/mihomo
GO_PKG_LDFLAGS_X:=$(GO_PKG)/constant.Version=$(PKG_BUILD_VERSION) $(GO_PKG)/constant.BuildTime=$(PKG_BUILD_TIME)
GO_PKG_TAGS:=with_gvisor

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk

define Package/clashoo
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Clashoo (Mihomo)
  DEPENDS:=$(GO_ARCH_DEPENDS) +ca-bundle +yq +firewall4 +ip-full +coreutils-nohup +coreutils-timeout +kmod-inet-diag +kmod-nft-socket +kmod-nft-tproxy +kmod-tun +kmod-dummy +unzip
  PROVIDES:=mihomo clash-meta
endef

define Package/clashoo/description
  Mihomo proxy core with runtime environment for Clashoo.
endef

define Package/clashoo/conffiles
/etc/config/clashoo
endef

define Package/clashoo/install
	$(call GoPackage/Package/Install/Bin,$(1))

	$(INSTALL_DIR) $(1)/usr/libexec/clashoo
	$(INSTALL_DIR) $(1)/usr/bin
	mv -f $(1)/usr/bin/mihomo $(1)/usr/libexec/clashoo/mihomo-stable
	ln -sf /usr/libexec/clashoo/mihomo-stable $(1)/usr/bin/mihomo
	ln -sf /usr/libexec/clashoo/mihomo-stable $(1)/usr/bin/clash-meta

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DIR) $(1)/etc/clashoo
	$(INSTALL_DIR) $(1)/etc/clashoo/provider
	$(INSTALL_DIR) $(1)/etc/clashoo/proxyprovider
	$(INSTALL_DIR) $(1)/etc/clashoo/ruleprovider
	$(INSTALL_DIR) $(1)/usr/share/clashoo
	$(INSTALL_DIR) $(1)/usr/share/clashbackup
	$(INSTALL_DIR) $(1)/usr/share/clashoo/config
	$(INSTALL_DIR) $(1)/usr/share/clashoo/config/sub
	$(INSTALL_DIR) $(1)/usr/share/clashoo/config/upload
	$(INSTALL_DIR) $(1)/usr/share/clashoo/config/custom

	$(INSTALL_BIN) $(CURDIR)/files/etc/init.d/clashoo $(1)/etc/init.d/clashoo
	$(INSTALL_CONF) $(CURDIR)/files/etc/config/clashoo $(1)/etc/config/clashoo
	$(INSTALL_DATA) $(CURDIR)/files/etc/config/clashoo $(1)/usr/share/clashoo/clashoo.default
	$(CP) $(CURDIR)/files/usr/share/clashoo/* $(1)/usr/share/clashoo/
	$(INSTALL_BIN) $(CURDIR)/files/usr/share/clashoo/migrate_lan_acl.sh $(1)/usr/share/clashoo/migrate_lan_acl.sh
	$(INSTALL_BIN) $(CURDIR)/files/usr/share/clashoo/migrate_fake_ip_filter.sh $(1)/usr/share/clashoo/migrate_fake_ip_filter.sh
	$(INSTALL_BIN) $(CURDIR)/files/usr/share/clashoo/detect_core_arch.sh $(1)/usr/share/clashoo/detect_core_arch.sh
	$(INSTALL_BIN) $(CURDIR)/files/usr/share/clashoo/diagnose_bypass.sh $(1)/usr/share/clashoo/diagnose_bypass.sh

	$(RM) $(1)/usr/share/clashoo/dashboard
	$(RM) $(1)/usr/share/clashoo/yacd
	$(RM) $(1)/usr/share/clashoo/update.log
	$(RM) $(1)/usr/share/clashoo/geoip.log
	$(RM) $(1)/usr/share/clashoo/core_down_complete
endef

define Package/clashoo/preinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	save_core() {
		src="$$1"
		dst="$$2"
		[ -f "$$src" ] && [ ! -L "$$src" ] || return 0
		if [ -e "$$dst" ] || [ -L "$$dst" ]; then return 0; fi
		mkdir -p "$$(dirname "$$dst")" || return 1
		tmp="$$dst.tmp.$$$$"
		cp "$$src" "$$tmp" && chmod 0755 "$$tmp" && cmp -s "$$src" "$$tmp" || {
			rm -f "$$tmp"
			return 1
		}
		if command -v sha256sum >/dev/null 2>&1; then
			old_hash="$$(sha256sum "$$src" | awk '{print $$1}')"
			new_hash="$$(sha256sum "$$tmp" | awk '{print $$1}')"
			[ "$$old_hash" = "$$new_hash" ] || {
				rm -f "$$tmp"
				return 1
			}
		fi
		mv -f "$$tmp" "$$dst"
	}
	save_core /usr/bin/mihomo /usr/share/clashoo/bin/mihomo-alpha || exit 1
	save_core /usr/bin/mihomo-stable /usr/share/clashoo/bin/mihomo-stable || exit 1
	if [ -x /usr/bin/clash-meta ] && [ ! -L /usr/bin/clash-meta ] && [ ! -e /usr/share/clashoo/bin/mihomo-stable ]; then
		if ! /usr/bin/clash-meta -v 2>/dev/null | grep -Eiq '(alpha|beta|rc|pre|smart)'; then
			save_core /usr/bin/clash-meta /usr/share/clashoo/bin/mihomo-stable || exit 1
		fi
	fi
fi
exit 0
endef

define Package/clashoo/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	rm -f /usr/share/clashoo/check_luci_version.sh /usr/share/clashoo/check_clash_meta_version.sh /usr/share/clashoo/check_mihomo_core_version.sh
	rm -f /usr/share/clashoo/cuslist.sh /usr/share/clashoo/groups.sh /usr/share/clashoo/load_groups.sh /usr/share/clashoo/panel_diag.sh
	rm -f /usr/share/clashoo/rmlist.sh /usr/share/clashoo/uplist.sh /usr/share/clashoo/rpc_restart_async.sh /usr/share/clashoo/rpc_update_china_ip_async.sh
	rm -rf /usr/share/clashoo/create
	# 旧方案把 stable 内核放在 /usr/bin/mihomo-stable，现方案改用
	# /usr/libexec/clashoo/mihomo-stable（随包）+ /usr/share/clashoo/bin/（自定义下载）。
	# preinst 已把它抄到 /usr/share/clashoo/bin/mihomo-stable，确认内容相同后才删
	# 旧位置；目标已有其他自定义内核时保留旧文件，避免误删。
	if [ -f /usr/share/clashoo/bin/mihomo-stable ] && [ -f /usr/bin/mihomo-stable ] && [ ! -L /usr/bin/mihomo-stable ] && cmp -s /usr/bin/mihomo-stable /usr/share/clashoo/bin/mihomo-stable; then
		rm -f /usr/bin/mihomo-stable
	fi
	/usr/share/clashoo/migrate_lan_acl.sh >/dev/null 2>&1 || true
	/usr/share/clashoo/migrate_fake_ip_filter.sh >/dev/null 2>&1 || true
	/usr/share/clashoo/detect_core_arch.sh >/dev/null 2>&1 || true
	if [ "$$(uci -q get clashoo.config.enable 2>/dev/null)" = "1" ]; then
		/etc/init.d/clashoo enable 2>/dev/null || true
	else
		/etc/init.d/clashoo disable 2>/dev/null || true
	fi
fi
exit 0
endef

define Build/Prepare
	$(Build/Prepare/Default)
	$(RM) -r $(PKG_BUILD_DIR)/rules/logic_test
endef

$(eval $(call GoBinPackage,clashoo))
$(eval $(call BuildPackage,clashoo))
