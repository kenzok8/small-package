#
# Copyright (C) 2020 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=supervisor
PKG_VERSION:=4.1.0
PKG_RELEASE:=1

PYPI_NAME:=supervisor
PKG_HASH:=2dc86fe0476e945e61483d614ceb2cf4f93b95282eb243bdf792621994360383

PKG_MAINTAINER:=[CTCGFW]Project OpenWrt <contact@project-openwrt.eu.org>
PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

include $(TOPDIR)/feeds/packages/lang/python/pypi.mk
include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/python/python3-package.mk

define Package/supervisor
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=A system for controlling process state under UNIX
  URL:=http://supervisord.org
  DEPENDS:= \
    +python3 \
    +python3-setuptools
  VARIANT:=python3
endef

define Package/supervisor/description
  Supervisor is a client/server system that allows its users
  to control a number of processes on UNIX-like operating systems.
endef

$(eval $(call Py3Package,supervisor))
$(eval $(call BuildPackage,supervisor))
$(eval $(call BuildPackage,supervisor-src))

