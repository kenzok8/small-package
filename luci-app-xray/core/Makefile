include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-xray
PKG_VERSION:=3.4.1
PKG_RELEASE:=1

PKG_LICENSE:=MPLv2
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=yichya <mail@yichya.dev>
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=Custom
	CATEGORY:=Extra packages
	TITLE:=LuCI Support for Xray
	DEPENDS:=firewall4 +kmod-nft-tproxy +luci-base +xray-core +dnsmasq +ca-bundle
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	LuCI Support for Xray (Client-side Rendered).
endef

define Package/$(PKG_NAME)/config
menu "luci-app-xray Configuration"
	depends on PACKAGE_$(PKG_NAME)

config PACKAGE_XRAY_INCLUDE_CLOUDFLARE_ORIGIN_ROOT_CA
	bool "Include Cloudflare Origin Root CA"
	default n

config PACKAGE_XRAY_RLIMIT_NOFILE_LARGE
	bool "Increase Max Open Files Limit (recommended)"
	default y

config PACKAGE_XRAY_RESTART_DNSMASQ_ON_IFACE_CHANGE
	bool "Restart dnsmasq on interface change (select this if using dnsmasq v2.87)"
	default n

config PACKAGE_XRAY_IGNORE_TP_SPEC_DEF_GW
	bool "Ignore TP_SPEC_DEF_GW (select this if using private IPv4 address)"
	default n

choice
	prompt "Limit memory use by setting rlimit_data (experimental)"
	default PACKAGE_XRAY_RLIMIT_DATA_UNLIMITED
	config PACKAGE_XRAY_RLIMIT_DATA_UNLIMITED
		bool "Not limited"
	config PACKAGE_XRAY_RLIMIT_DATA_SMALL
		bool "Small limit (about 50MB)"
	config PACKAGE_XRAY_RLIMIT_DATA_LARGE
		bool "Large limit (about 321MB)"
endchoice

endmenu
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
if [[ -z "$${IPKG_INSTROOT}" ]]; then
	if [[ -f /etc/uci-defaults/xray_core ]]; then
		( . /etc/uci-defaults/xray_core ) && rm -f /etc/uci-defaults/xray_core
	fi
	rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
fi
exit 0
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/xray_core
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/luci-uploads/xray
	$(INSTALL_DIR) $(1)/etc/ssl/certs
ifdef CONFIG_PACKAGE_XRAY_INCLUDE_CLOUDFLARE_ORIGIN_ROOT_CA
	$(INSTALL_DATA) ./root/etc/ssl/certs/origin_ca_ecc_root.pem $(1)/etc/ssl/certs/origin_ca_ecc_root.pem
endif
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./root/etc/init.d/xray_core $(1)/etc/init.d/xray_core
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./root/etc/config/xray_core $(1)/etc/config/xray_core
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./root/etc/uci-defaults/xray_core $(1)/etc/uci-defaults/xray_core
	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_BIN) ./root/etc/hotplug.d/iface/01-transparent-proxy-ipset $(1)/etc/hotplug.d/iface/01-transparent-proxy-ipset
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/xray
	$(INSTALL_DATA) ./root/www/luci-static/resources/view/xray/core.js $(1)/www/luci-static/resources/view/xray/core.js
	$(INSTALL_DATA) ./root/www/luci-static/resources/view/xray/preview.js $(1)/www/luci-static/resources/view/xray/preview.js
	$(INSTALL_DATA) ./root/www/luci-static/resources/view/xray/protocol.js $(1)/www/luci-static/resources/view/xray/protocol.js
	$(INSTALL_DATA) ./root/www/luci-static/resources/view/xray/shared.js $(1)/www/luci-static/resources/view/xray/shared.js
	$(INSTALL_DATA) ./root/www/luci-static/resources/view/xray/transport.js $(1)/www/luci-static/resources/view/xray/transport.js
	$(INSTALL_DIR) $(1)/usr/libexec/rpcd
	$(INSTALL_BIN) ./root/usr/libexec/rpcd/xray $(1)/usr/libexec/rpcd/xray
	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DATA) ./root/usr/share/luci/menu.d/luci-app-xray.json $(1)/usr/share/luci/menu.d/luci-app-xray.json
	$(INSTALL_DIR) $(1)/usr/share/nftables.d/table-pre
	$(INSTALL_DATA) ./root/usr/share/nftables.d/table-pre/xray_core.nft $(1)/usr/share/nftables.d/table-pre/xray_core.nft
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./root/usr/share/rpcd/acl.d/luci-app-xray.json $(1)/usr/share/rpcd/acl.d/luci-app-xray.json
	$(INSTALL_DIR) $(1)/usr/share/xray
	$(LN) /var/run/xray.pid $(1)/usr/share/xray/xray.pid
	$(LN) /usr/bin/xray $(1)/usr/share/xray/xray
ifdef CONFIG_PACKAGE_XRAY_IGNORE_TP_SPEC_DEF_GW
	$(INSTALL_DATA) ./root/usr/share/xray/ignore_tp_spec_def_gw $(1)/usr/share/xray/ignore_tp_spec_def_gw
endif
ifdef CONFIG_PACKAGE_XRAY_RESTART_DNSMASQ_ON_IFACE_CHANGE
	$(INSTALL_DATA) ./root/usr/share/xray/restart_dnsmasq_on_iface_change $(1)/usr/share/xray/restart_dnsmasq_on_iface_change
endif
ifdef CONFIG_PACKAGE_XRAY_RLIMIT_NOFILE_LARGE
	$(INSTALL_DATA) ./root/usr/share/xray/rlimit_nofile_large $(1)/usr/share/xray/rlimit_nofile
endif
ifdef CONFIG_PACKAGE_XRAY_RLIMIT_DATA_SMALL
	$(INSTALL_DATA) ./root/usr/share/xray/rlimit_data_small $(1)/usr/share/xray/rlimit_data
endif
ifdef CONFIG_PACKAGE_XRAY_RLIMIT_DATA_LARGE
	$(INSTALL_DATA) ./root/usr/share/xray/rlimit_data_large $(1)/usr/share/xray/rlimit_data
endif
	$(INSTALL_BIN) ./root/usr/share/xray/default_gateway.uc $(1)/usr/share/xray/default_gateway.uc
	$(INSTALL_BIN) ./root/usr/share/xray/dnsmasq_include.ut $(1)/usr/share/xray/dnsmasq_include.ut
	$(INSTALL_BIN) ./root/usr/share/xray/firewall_include.ut $(1)/usr/share/xray/firewall_include.ut
	$(INSTALL_BIN) ./root/usr/share/xray/gen_config.uc $(1)/usr/share/xray/gen_config.uc
	$(INSTALL_DIR) $(1)/usr/share/xray/common
	$(INSTALL_DATA) ./root/usr/share/xray/common/config.mjs $(1)/usr/share/xray/common/config.mjs
	$(INSTALL_DATA) ./root/usr/share/xray/common/stream.mjs $(1)/usr/share/xray/common/stream.mjs
	$(INSTALL_DATA) ./root/usr/share/xray/common/tls.mjs $(1)/usr/share/xray/common/tls.mjs
	$(INSTALL_DIR) $(1)/usr/share/xray/feature
	$(INSTALL_DATA) ./root/usr/share/xray/feature/bridge.mjs $(1)/usr/share/xray/feature/bridge.mjs
	$(INSTALL_DATA) ./root/usr/share/xray/feature/dns.mjs $(1)/usr/share/xray/feature/dns.mjs
	$(INSTALL_DATA) ./root/usr/share/xray/feature/fake_dns.mjs $(1)/usr/share/xray/feature/fake_dns.mjs
	$(INSTALL_DATA) ./root/usr/share/xray/feature/inbound.mjs $(1)/usr/share/xray/feature/inbound.mjs
	$(INSTALL_DATA) ./root/usr/share/xray/feature/manual_tproxy.mjs $(1)/usr/share/xray/feature/manual_tproxy.mjs
	$(INSTALL_DATA) ./root/usr/share/xray/feature/outbound.mjs $(1)/usr/share/xray/feature/outbound.mjs
	$(INSTALL_DATA) ./root/usr/share/xray/feature/system.mjs $(1)/usr/share/xray/feature/system.mjs
	$(INSTALL_DIR) $(1)/usr/share/xray/protocol
	$(INSTALL_DATA) ./root/usr/share/xray/protocol/shadowsocks.mjs $(1)/usr/share/xray/protocol/shadowsocks.mjs
	$(INSTALL_DATA) ./root/usr/share/xray/protocol/trojan.mjs $(1)/usr/share/xray/protocol/trojan.mjs
	$(INSTALL_DATA) ./root/usr/share/xray/protocol/vless.mjs $(1)/usr/share/xray/protocol/vless.mjs
	$(INSTALL_DATA) ./root/usr/share/xray/protocol/vmess.mjs $(1)/usr/share/xray/protocol/vmess.mjs
	$(INSTALL_DATA) ./root/usr/share/xray/protocol/socks.mjs $(1)/usr/share/xray/protocol/socks.mjs
	$(INSTALL_DATA) ./root/usr/share/xray/protocol/http.mjs $(1)/usr/share/xray/protocol/http.mjs
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
