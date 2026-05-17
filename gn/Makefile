# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2022 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=gn
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://gn.googlesource.com/gn.git
PKG_SOURCE_DATE:=2026-05-11
PKG_SOURCE_VERSION:=068dd892acb22dc21d9e17691266c8499ba2d6c8
PKG_MIRROR_HASH:=21738e255e5cc63aac72d61e017043cf00c9ae9a98b7f2ae82577b7456e7d09e

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
		--no-last-commit-position \
		--allow-warnings
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
