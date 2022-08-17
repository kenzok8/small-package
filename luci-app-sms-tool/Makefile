#
# Copyright 2020-2022 Rafał Wabik - IceG - From eko.one.pl forum
# Licensed to the GNU General Public License v3.0.

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-sms-tool
LUCI_TITLE:=LuCI Support for sms_tool
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+sms-tool +kmod-usb-serial +kmod-usb-serial-option +luci-compat
PKG_VERSION:=1.9.5-20220816

include $(TOPDIR)/feeds/luci/luci.mk

$(eval $(call BuildPackage,$(PKG_NAME)))

# call BuildPackage - OpenWrt buildroot signature
