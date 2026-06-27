include $(TOPDIR)/rules.mk

PKG_NAME:=clashoo
PKG_SHORT_SHA:=24b6de7
PKG_COMMIT_DATE:=2026.06.26

PKG_VERSION:=$(PKG_COMMIT_DATE)~$(PKG_SHORT_SHA)
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-alpha-$(PKG_SHORT_SHA).tar.gz
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-alpha-$(PKG_SHORT_SHA)
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-alpha-$(PKG_SHORT_SHA)
PKG_SOURCE_URL:=https://github.com/kenzok8/openwrt-clashoo/releases/download/mihomo-src
PKG_SOURCE_VERSION:=24b6de71fc1c4ea282dcbc7b65a8bcbcc0c75e6c
PKG_HASH:=76967080afe5b509ea44601e64eb864f3b2d4e3268f6166297432e64a051b7c0
PKG_BUILD_VERSION:=alpha-$(PKG_SHORT_SHA)

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
  DEPENDS:=$(GO_ARCH_DEPENDS) +ca-bundle +yq +firewall4 +ip-full +coreutils-nohup +kmod-inet-diag +kmod-nft-socket +kmod-nft-tproxy +kmod-tun +kmod-dummy +unzip
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

	$(INSTALL_DIR) $(1)/usr/bin
	ln -sf /usr/bin/mihomo $(1)/usr/bin/clash-meta

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

	$(RM) $(1)/usr/share/clashoo/dashboard
	$(RM) $(1)/usr/share/clashoo/yacd
	$(RM) $(1)/usr/share/clashoo/update.log
	$(RM) $(1)/usr/share/clashoo/geoip.log
	$(RM) $(1)/usr/share/clashoo/core_down_complete
endef

define Package/clashoo/postinst
#!/bin/sh
if [ -z "${IPKG_INSTROOT}" ]; then
	[ -x /usr/bin/mihomo ] && [ ! -x /usr/bin/clash-meta ] && ln -sf /usr/bin/mihomo /usr/bin/clash-meta
	rm -f /usr/share/clashoo/check_luci_version.sh /usr/share/clashoo/check_clash_meta_version.sh /usr/share/clashoo/check_mihomo_core_version.sh
	rm -f /usr/share/clashoo/cuslist.sh /usr/share/clashoo/groups.sh /usr/share/clashoo/load_groups.sh /usr/share/clashoo/panel_diag.sh
	rm -f /usr/share/clashoo/rmlist.sh /usr/share/clashoo/uplist.sh /usr/share/clashoo/rpc_restart_async.sh /usr/share/clashoo/rpc_update_china_ip_async.sh
	rm -rf /usr/share/clashoo/create
	if [ "$(uci -q get clashoo.config.enable 2>/dev/null)" = "1" ]; then
		/etc/init.d/clashoo enable 2>/dev/null || true
	else
		/etc/init.d/clashoo disable 2>/dev/null || true
	fi
fi
exit 0
endef

define Package/clashoo/prerm
#!/bin/sh
if [ -z "${IPKG_INSTROOT}" ]; then
	/etc/init.d/clashoo stop >/dev/null 2>&1
	/etc/init.d/clashoo disable 2>/dev/null
fi
exit 0
endef

define Build/Prepare
	$(Build/Prepare/Default)
	$(RM) -r $(PKG_BUILD_DIR)/rules/logic_test
endef

$(eval $(call GoBinPackage,clashoo))
$(eval $(call BuildPackage,clashoo))
