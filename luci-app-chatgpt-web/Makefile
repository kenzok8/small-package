# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2023-2025  sirpdboy  <herboy2008@gmail.com> https://github.com/sirpdboy/luci-app-chatgpt-web
# 
# This is free software, licensed under the Apache License, Version 2.0 .
#
include $(TOPDIR)/rules.mk

NAME:=chatgpt-web
PKG_NAME:=luci-app-$(NAME)
PKG_VERSION:=1.2.1
PKG_RELEASE:=16

LUCI_TITLE:=LuCI Support for chatgpt-web Client
LUCI_PKGARCH:=all

define Package/$(PKG_NAME)/conffiles
/etc/config/chatgpt-web
endef
include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
