# Copyright 2020 Wojciech Jowsa (wojciech.jowsa@gmail.com)
# This is free software, licensed under the Apache License, Version 2.0

include $(TOPDIR)/rules.mk

LUCI_TITLE:=Packet capture application
LUCI_DEPENDS:=+luci-mod-admin-full +tcpdump +coreutils +coreutils-timeout

PKG_MAINTAINER:=Wojciech Jowsa <wojciech.jowsa@gmail.com>
PKG_LICENSE:=Apache-2.0

define Package/luci-app-packet-capture/conffiles
/etc/config/packet_capture
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signatureet
