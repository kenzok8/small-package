# Copyright (C) 2021-2022 Lienol <lawlienol@gmail.com>

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-openvpn-client
PKG_VERSION:=20211229
PKG_RELEASE:=1

LUCI_TITLE:=LuCI support for OpenVPN Client
LUCI_DEPENDS:=+openvpn-openssl +kmod-tun
LUCI_PKGARCH:=all

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
