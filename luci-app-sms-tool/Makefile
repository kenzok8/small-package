# Copyright 2020-2022 Rafał Wabik - IceG - From eko.one.pl forum
# Licensed to the GNU General Public License v3.0.

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-sms-tool
LUCI_TITLE:=LuCI Support for sms_tool
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+sms-tool +kmod-usb-serial +kmod-usb-serial-option +luci-compat
PKG_VERSION:=1.9.4-20220325
PKG_LICENSE:=GPLv3

define Package/$(PKG_NAME)
	$(call Package/luci/webtemplate)
	TITLE:=$(LUCI_TITLE)
	DEPENDS:=$(LUCI_DEPENDS)
endef

define Package/$(PKG_NAME)/description
	LuCI Support for sms_tool.
endef

define Package/luci-app-sms-tool/postinst
#!/bin/sh
chmod +x /sbin/cronsync.sh
chmod +x /sbin/set_sms_ports.sh
chmod +x /sbin/smsled-init.sh
chmod +x /sbin/smsled.sh
rm -rf /tmp/luci-indexcache
rm -rf /tmp/luci-modulecache/
/sbin/set_sms_ports.sh
exit 0
endef

include $(TOPDIR)/feeds/luci/luci.mk

$(eval $(call BuildPackage,$(PKG_NAME)))

# call BuildPackage - OpenWrt buildroot signature
