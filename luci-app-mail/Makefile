#
# Copyright (C) 2018-2019 Ycarus (Yannick Chabanois) <ycarus@zugaina.org>
#
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI Mail Configuration
LUCI_DEPENDS:=+msmtp-mta +luci-compat

PKG_LICENSE:=GPLv3

define Package/luci-app-mail/conffiles
/etc/config/mail
endef

#include ../luci/luci.mk
include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
