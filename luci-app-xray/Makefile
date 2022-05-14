include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-xray
PKG_VERSION:=1.10.2
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
	DEPENDS:=+luci-base +xray-core +dnsmasq +ipset +firewall +iptables +iptables-mod-tproxy +ca-bundle
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

config PACKAGE_XRAY_INFINITE_RETRY_ON_STARTUP
	bool "Retry infinitely on Xray startup (may solve some startup problems)"
	default n

config PACKAGE_XRAY_RLIMIT_NOFILE_LARGE
	bool "Increase Max Open Files Limit (recommended)"
	default y

choice
	prompt "Limit memory use by setting rlimit_data (experimental)"
	default PACKAGE_XRAY_RLIMIT_DATA_UNLIMITED
	config PACKAGE_XRAY_RLIMIT_DATA_UNLIMITED
		bool "Not limited"
	config PACKAGE_XRAY_RLIMIT_DATA_SMALL
		bool "Small limit (about 50MB)"
	config PACKAGE_XRAY_RLIMIT_DATA_LARGE
		bool "Large limit (about 210MB)"
endchoice

endmenu
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
if [[ ! -f $${IPKG_INSTROOT}/usr/share/xray/xray.init.replaced ]]; then
	if [[ ! -f $${IPKG_INSTROOT}/etc/init.d/xray ]]; then
	    echo "echo This file does nothing" > $${IPKG_INSTROOT}/etc/init.d/xray
	fi
	mv $${IPKG_INSTROOT}/etc/init.d/xray $${IPKG_INSTROOT}/usr/share/xray/xray.init.replaced
	mkdir -p $${IPKG_INSTROOT}/etc/config
	mv $${IPKG_INSTROOT}/tmp/xray.conf $${IPKG_INSTROOT}/etc/config/xray
fi
rm -f $${IPKG_INSTROOT}/tmp/xray.conf
mkdir -p $${IPKG_INSTROOT}/etc/init.d
mv $${IPKG_INSTROOT}/tmp/xray.init $${IPKG_INSTROOT}/etc/init.d/xray
if [[ -z "$${IPKG_INSTROOT}" ]]; then
	if [[ -f /etc/uci-defaults/xray ]]; then
		( . /etc/uci-defaults/xray ) && rm -f /etc/uci-defaults/xray
	fi
	rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
fi
exit 0
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/xray
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/tmp
	$(INSTALL_BIN) ./root/etc/init.d/xray $(1)/tmp/xray.init
	$(INSTALL_DATA) ./root/etc/config/xray $(1)/tmp/xray.conf
	$(INSTALL_DIR) $(1)/etc/luci-uploads/xray
	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_BIN) ./root/etc/hotplug.d/iface/01-transparent-proxy-ipset $(1)/etc/hotplug.d/iface/01-transparent-proxy-ipset
	$(INSTALL_DIR) $(1)/etc/ssl/certs
ifdef CONFIG_PACKAGE_XRAY_INCLUDE_CLOUDFLARE_ORIGIN_ROOT_CA
	$(INSTALL_DATA) ./root/etc/ssl/certs/origin_ca_ecc_root.pem $(1)/etc/ssl/certs/origin_ca_ecc_root.pem
endif
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./root/etc/uci-defaults/xray $(1)/etc/uci-defaults/xray
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view
	$(INSTALL_DATA) ./root/www/luci-static/resources/view/xray.js $(1)/www/luci-static/resources/view/xray.js
	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DATA) ./root/usr/share/luci/menu.d/luci-app-xray.json $(1)/usr/share/luci/menu.d/luci-app-xray.json
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./root/usr/share/rpcd/acl.d/luci-app-xray.json $(1)/usr/share/rpcd/acl.d/luci-app-xray.json
	$(INSTALL_DIR) $(1)/usr/share/xray
ifdef CONFIG_PACKAGE_XRAY_INFINITE_RETRY_ON_STARTUP
	$(INSTALL_DATA) ./root/usr/share/xray/infinite_retry $(1)/usr/share/xray/infinite_retry
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
	$(INSTALL_BIN) ./root/usr/share/xray/gen_ipset_rules.lua $(1)/usr/share/xray/gen_ipset_rules.lua
	$(INSTALL_BIN) ./root/usr/share/xray/gen_ipset_rules_extra_normal.lua $(1)/usr/share/xray/gen_ipset_rules_extra.lua
	$(INSTALL_BIN) ./root/usr/share/xray/gen_config.lua $(1)/usr/share/xray/gen_config.lua
	$(INSTALL_BIN) ./root/usr/share/xray/firewall_include.lua $(1)/usr/share/xray/firewall_include.lua
	$(INSTALL_DIR) $(1)/usr/libexec/rpcd
	$(INSTALL_BIN) ./root/usr/libexec/rpcd/xray $(1)/usr/libexec/rpcd/xray
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
