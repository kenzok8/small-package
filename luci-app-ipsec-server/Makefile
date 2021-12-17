# Copyright (C) 2018-2021 Lienol <lawlienol@gmail.com>
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI support for IPSec VPN Server
LUCI_DEPENDS:=+strongswan +strongswan-minimal +strongswan-mod-kernel-libipsec +strongswan-mod-openssl +strongswan-mod-xauth-generic +xl2tpd +luci-lib-jsonc +kmod-tun
LUCI_PKGARCH:=all
PKG_VERSION:=20211216
PKG_RELEASE:=2

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
