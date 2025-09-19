#
# [K] 2022
# This is free software, licensed under the GNU General Public License v2.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=my-dnshelper
PKG_VERSION:=1.1
PKG_RELEASE:=3

PKG_MAINTAINER:=kongfl888 <kongfl888@outlook.com>
PKG_LICENSE:=GPLv2

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=net
  CATEGORY:=Network
  TITLE:=my-dnshelper
  PKGARCH:=all
  URL:=https://github.com/kongfl888/openwrt-my-dnshelper
endef

define Package/$(PKG_NAME)/description
	my-dnshelper which is your helper of setting dns server of your openwrt.
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/my-dnshelper
/etc/my-dnshelper/
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/etc/config/my-dnshelper  $(1)/etc/config/
	$(INSTALL_DIR) $(1)/etc/my-dnshelper
	$(INSTALL_DATA) ./files/etc/my-dnshelper/* $(1)/etc/my-dnshelper/
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/my-dnshelper $(1)/etc/init.d/my-dnshelper
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/usr/bin/my-dnshelper $(1)/usr/bin/my-dnshelper
	$(INSTALL_DIR) $(1)/usr/share/my-dnshelper
	$(INSTALL_BIN) ./files/usr/share/my-dnshelper/* $(1)/usr/share/my-dnshelper/

endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
	chmod a+x ${IPKG_INSTROOT}/etc/init.d/my-dnshelper >/dev/null 2>&1 || echo ""
	chmod a+x ${IPKG_INSTROOT}/usr/share/my-dnshelper/* >/dev/null 2>&1 || echo ""
	chmod a+x ${IPKG_INSTROOT}/usr/bin/my-dnshelper >/dev/null 2>&1 || echo ""
	exit 0
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh
uci -q set my-dnshelper.@my-dnshelper[0].enable='0' >/dev/null 2>&1
uci commit my-dnshelper || echo ""
/etc/init.d/my-dnshelper stop >/dev/null 2>&1
exit 0
endef

define Package/$(PKG_NAME)/postrm
#!/bin/sh
	rm -rf /etc/my-dnshelper >/dev/null 2>&1
	rm -rf /usr/share/my-dnshelper >/dev/null 2>&1
	rm -rf /var/etc/dnsmasq-my-dnshelper.d >/dev/null 2>&1
	exit 0
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
