#
# Copyright (C) 2019 Openwrt.org
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

PKG_NAME:=qttools
PKG_BASE:=5.15
PKG_BUGFIX:=8
PKG_VERSION:=$(PKG_BASE).$(PKG_BUGFIX)
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-everywhere-opensource-src-$(PKG_VERSION).tar.xz
PKG_SOURCE_URL:= \
		http://master.qt.io/archive/qt/$(PKG_BASE)/$(PKG_VERSION)/submodules \
		http://mirrors.tuna.tsinghua.edu.cn/qt/archive/qt/$(PKG_BASE)/$(PKG_VERSION)/submodules \
		http://qt.mirror.constant.com/archive/qt/$(PKG_BASE)/$(PKG_VERSION)/submodules
PKG_HASH:=a3bef8de13032dae17450f5df35e8abbb4f41f71e3b628871d3da5633577e9c4

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-everywhere-src-$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1
PKG_BUILD_DEPENDS:=qtbase

include $(INCLUDE_DIR)/package.mk

define Package/qttools
  SECTION:=libs
  CATEGORY:=Libraries
  SUBMENU:=Qt5
  TITLE:=qttools
  URL:=http://qt-project.org
  BUILDONLY:=1
endef

define Build/Configure
	cd $(PKG_BUILD_DIR) && qmake -o Makefile qttools.pro
endef

define Build/Compile
	+$(MAKE) $(PKG_JOBS) -C $(PKG_BUILD_DIR)
endef

define Build/InstallDev
	$(MAKE) -C $(PKG_BUILD_DIR) install
endef

$(eval $(call BuildPackage,qttools))
