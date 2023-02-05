# Copyright (C) 2018-2021 Lienol <lawlienol@gmail.com>
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-ipsec-server
PKG_VERSION:=20211223
PKG_RELEASE:=3

PKG_MAINTAINER:=Lienol <lawlienol@gmail.com>

LUCI_TITLE:=LuCI support for IPSec VPN Server
LUCI_DEPENDS:=+kmod-tun +luci-lib-jsonc +xl2tpd +strongswan \
  +PACKAGE_strongswan:strongswan-mod-kernel-libipsec \
  +PACKAGE_strongswan:strongswan-mod-openssl \
  +PACKAGE_strongswan:strongswan-mod-xauth-generic \
  +(PACKAGE_strongswan-mod-kdf||PACKAGE_strongswan-mod-openssl||PACKAGE_strongswan-mod-wolfssl):strongswan-minimal
LUCI_PKGARCH:=all

define Package/$(PKG_NAME)/conffiles
/etc/config/luci-app-ipsec-server
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
