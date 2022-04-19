include $(TOPDIR)/rules.mk

PKG_NAME:=ddns-scripts-aliyun
PKG_VERSION:=1.0.2
PKG_RELEASE:=1

PKG_LICENSE:=GPLv2
PKG_MAINTAINER:=Sense <sensec@gmail.com>

PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=IP Addresses and Names
	TITLE:=Extension for aliyun.com (require curl)
	PKGARCH:=all
	DEPENDS:=+ddns-scripts +curl +jshn +openssl-util
endef

define Package/$(PKG_NAME)/description
	Dynamic DNS Client scripts extension for aliyun.com API v1 (require curl)
	It requires:
	"option username" to be a valid aliyun access key id
	"option password" to be the matching aliyun access key secret
	"option domain" the dns domain to update the record for (eg. A-record: home.<example.com>)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/ddns
	$(INSTALL_BIN) ./update_aliyun_com.sh $(1)/usr/lib/ddns

	$(INSTALL_DIR) $(1)/usr/share/ddns/default
	$(INSTALL_DATA) ./aliyun.com.json $(1)/usr/share/ddns/default
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	/etc/init.d/ddns stop
fi
if [ -w $${IPKG_INSTROOT}/etc/ddns/services ]; then
	/bin/sed -i '/aliyun\.com/d' $${IPKG_INSTROOT}/etc/ddns/services >/dev/null 2>&1
	/bin/sed -i '/aliyun\.com/d' $${IPKG_INSTROOT}/etc/ddns/services_ipv6 >/dev/null 2>&1
fi
exit 0
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
if [ -w $${IPKG_INSTROOT}/etc/ddns/services ]; then
	/bin/sed -i '/aliyun\.com/d' $${IPKG_INSTROOT}/etc/ddns/services >/dev/null 2>&1
	/bin/sed -i '/aliyun\.com/d' $${IPKG_INSTROOT}/etc/ddns/services_ipv6 >/dev/null 2>&1
	printf "%s\\t\\t%s\\n" '"aliyun.com"' '"update_aliyun_com.sh"' >> $${IPKG_INSTROOT}/etc/ddns/services
	printf "%s\\t\\t%s\\n" '"aliyun.com"' '"update_aliyun_com.sh"' >> $${IPKG_INSTROOT}/etc/ddns/services_ipv6
fi
if [ -z "$${IPKG_INSTROOT}" ]; then
	/etc/init.d/ddns enabled
	/etc/init.d/ddns start
fi
exit 0
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
