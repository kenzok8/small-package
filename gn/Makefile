# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2022 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=gn
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://gn.googlesource.com/gn.git
PKG_SOURCE_DATE:=2023-08-01
PKG_SOURCE_VERSION:=811d332bd90551342c5cbd39e133aa276022d7f8
PKG_MIRROR_HASH:=0b6e46de619f3e9a17eef71a010660aebd349a5ac3462f7c12de5cb3f6300dbb

PKG_LICENSE:=BSD 3-Clause
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Tianling Shen <cnsztl@immortalwrt.org>

PKG_HOST_ONLY:=1
HOST_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/host-build.mk
include $(INCLUDE_DIR)/package.mk

define Package/gn
  SECTION:=devel
  CATEGORY:=Development
  TITLE:=A meta-build system that generates build files for Ninja
  URL:=https://gn.googlesource.com/gn/
  BUILDONLY:=1
endef

define Package/gn/description
  GN can generate Ninja build files for C, C++, Rust, Objective C,
  and Swift source on most popular platforms.
endef

define Host/Configure
	$(PYTHON) $(HOST_BUILD_DIR)/build/gen.py \
		--no-last-commit-position
endef

define Host/Compile
	+$(NINJA) -C $(HOST_BUILD_DIR)/out
endef

define Host/Install
	$(INSTALL_DIR) $(STAGING_DIR_HOSTPKG)/bin/
	$(INSTALL_BIN) $(HOST_BUILD_DIR)/out/gn $(STAGING_DIR_HOSTPKG)/bin/
endef

define Host/Clean
	$(RM) $(STAGING_DIR_HOSTPKG)/bin/gn
endef

$(eval $(call HostBuild))
$(eval $(call BuildPackage,gn))
