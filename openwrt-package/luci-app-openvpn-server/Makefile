# Copyright (C) 2021-2025 Lienol <lawlienol@gmail.com>

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-openvpn-server
PKG_VERSION:=20250227
PKG_RELEASE:=1

LUCI_TITLE:=LuCI support for OpenVPN Server
LUCI_DEPENDS:=+openvpn-easy-rsa +openvpn-openssl +kmod-tun +@OPENVPN_openssl_ENABLE_MANAGEMENT
LUCI_PKGARCH:=all

define Package/$(PKG_NAME)/conffiles
/etc/config/luci-app-openvpn
/usr/share/openvpn-server/ca.crt
/usr/share/openvpn-server/dh.pem
/usr/share/openvpn-server/server.crt
/usr/share/openvpn-server/server.key
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
