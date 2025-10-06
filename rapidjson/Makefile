# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=rapidjson
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/Tencent/rapidjson.git
PKG_SOURCE_DATE:=2025-02-05
PKG_SOURCE_VERSION:=24b5e7a8b27f42fa16b96fc70aade9106cf7102f
PKG_MIRROR_HASH:=7ebe34336510f598a118922440c43dba5b4ba93b2b8b9f46d5190514612bc3bd

PKG_LICENSE:=BSD 3-Clause
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Tianling Shen <cnsztl@immortalwrt.org>

PKG_BUILD_PARALLEL:=1
CMAKE_INSTALL:=1

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/rapidjson
  SECTION:=lib
  CATEGORY:=Libraries
  URL:=https://github.com/Tencent/rapidjson
  TITLE:=rapidjson JSON parser/generator for C++
  BUILDONLY:=1
endef

define Package/rapidjson/description
  A fast JSON parser/generator for C++ with both SAX/DOM style API
endef

CMAKE_OPTIONS+= \
	-DRAPIDJSON_BUILD_DOC=OFF \
	-DRAPIDJSON_BUILD_EXAMPLES=OFF \
	-DRAPIDJSON_BUILD_TESTS=OFF

$(eval $(call BuildPackage,rapidjson))
