# Copyright (C) 2018-2022 Lienol
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI support for SoftEtherVPN
LUCI_DEPENDS:=+zlib +libpthread +librt +libreadline +libncurses +libiconv-full +kmod-tun +libopenssl +softethervpn-server
LUCI_PKGARCH:=all
PKG_VERSION:=20220102
PKG_RELEASE:=1

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
