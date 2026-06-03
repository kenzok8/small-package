include $(TOPDIR)/rules.mk

PKG_NAME:=momo
PKG_VERSION:=2026.06.03
PKG_RELEASE:=1

PKG_LICENSE:=GPL-3.0+
PKG_MAINTAINER:=Joseph Mory <morytyann@gmail.com>

include $(INCLUDE_DIR)/package.mk

define Package/momo
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Transparent Proxy with sing-box on OpenWrt.
  URL:=https://github.com/nikkinikki-org
  DEPENDS:=+ca-bundle +curl firewall4 +ip-full +kmod-inet-diag +kmod-nft-socket +kmod-nft-tproxy +kmod-tun +kmod-dummy +sing-box
endef

define Package/momo/conffiles
/etc/config/momo
endef

define Package/momo/install
	$(INSTALL_DIR) $(1)/etc/momo
	$(INSTALL_DIR) $(1)/etc/momo/ucode
	$(INSTALL_DIR) $(1)/etc/momo/scripts
	$(INSTALL_DIR) $(1)/etc/momo/firewall
	$(INSTALL_DIR) $(1)/etc/momo/profiles
	$(INSTALL_DIR) $(1)/etc/momo/subscriptions
	$(INSTALL_DIR) $(1)/etc/momo/run

	$(INSTALL_BIN) $(CURDIR)/files/ucode/include.uc $(1)/etc/momo/ucode/include.uc
	$(INSTALL_BIN) $(CURDIR)/files/ucode/mixin.uc $(1)/etc/momo/ucode/mixin.uc
	$(INSTALL_BIN) $(CURDIR)/files/ucode/hijack.ut $(1)/etc/momo/ucode/hijack.ut

	$(INSTALL_BIN) $(CURDIR)/files/scripts/include.sh $(1)/etc/momo/scripts/include.sh
	$(INSTALL_BIN) $(CURDIR)/files/scripts/firewall_include.sh $(1)/etc/momo/scripts/firewall_include.sh
	$(INSTALL_BIN) $(CURDIR)/files/scripts/debug.sh $(1)/etc/momo/scripts/debug.sh

	$(INSTALL_BIN) $(CURDIR)/files/firewall/geoip_cn.nft $(1)/etc/momo/firewall/geoip_cn.nft
	$(INSTALL_BIN) $(CURDIR)/files/firewall/geoip6_cn.nft $(1)/etc/momo/firewall/geoip6_cn.nft

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) $(CURDIR)/files/momo.conf $(1)/etc/config/momo

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(CURDIR)/files/momo.init $(1)/etc/init.d/momo

	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) $(CURDIR)/files/uci-defaults/firewall.sh $(1)/etc/uci-defaults/99_firewall_momo
	$(INSTALL_BIN) $(CURDIR)/files/uci-defaults/init.sh $(1)/etc/uci-defaults/99_init_momo
	$(INSTALL_BIN) $(CURDIR)/files/uci-defaults/migrate.sh $(1)/etc/uci-defaults/99_migrate_momo

	$(INSTALL_DIR) $(1)/lib/upgrade/keep.d
	$(INSTALL_DATA) $(CURDIR)/files/momo.upgrade $(1)/lib/upgrade/keep.d/momo
endef

define Package/momo/postrm
#!/bin/sh
if [ -z $${IPKG_INSTROOT} ]; then
	uci -q batch <<-EOF > /dev/null
		del firewall.momo
		commit firewall
	EOF
fi
endef

define Build/Compile

endef

$(eval $(call BuildPackage,momo))