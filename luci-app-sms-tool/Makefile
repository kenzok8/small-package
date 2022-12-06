#
# Copyright 2020-2022 Rafał Wabik - IceG - From eko.one.pl forum
# Licensed to the GNU General Public License v3.0.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-sms-tool
LUCI_TITLE:=LuCI Support for sms_tool
LUCI_DESCRIPTION:=LuCI interface for the sms_tool. The user interface supports SMS/USSD Codes/AT Commands.
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+sms-tool +kmod-usb-serial +kmod-usb-serial-option +comgt +luci-compat
PKG_VERSION:=1.9.5-20221121

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
