# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021-2022 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=gallery-dl
PKG_VERSION:=1.30.8
PKG_RELEASE:=1

PYPI_NAME:=gallery_dl
PKG_HASH:=66b740276753cd0eeef365c29eb140130f08359ff06008a497af855d00081d04

PKG_LICENSE:=GPL-2.0-only
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Tianling Shen <cnsztl@immortalwrt.org>

include $(TOPDIR)/feeds/packages/lang/python/pypi.mk
include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/python/python3-package.mk

define Package/gallery-dl
  SECTION:=multimedia
  CATEGORY:=Multimedia
  TITLE:=Command-line program to download image galleries and collections
  URL:=https://github.com/mikf/gallery-dl
  DEPENDS:= \
    +ca-bundle \
    +python3 \
    +python3-codecs \
    +python3-ctypes \
    +python3-email \
    +python3-requests \
    +python3-setuptools \
    +python3-xml
endef

define Package/gallery-dl/description
  gallery-dl is a command-line program to download image galleries
  and collections from several image hosting sites.

  It is a cross-platform tool with many configuration options and
  powerful filenaming capabilities.
endef

$(eval $(call Py3Package,gallery-dl))
$(eval $(call BuildPackage,gallery-dl))
$(eval $(call BuildPackage,gallery-dl-src))
