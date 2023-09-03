# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021-2023 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=gowebdav
PKG_VERSION:=0.0.5
PKG_RELEASE:=2

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/1715173329/gowebdav/tar.gz/v$(PKG_VERSION)?
PKG_HASH:=ee0ac5a52a3b7a1e1c687b850c3f7b55e10bbdc88da0b6b1dd8b790fc53d10c6

PKG_MAINTAINER:=Tianling Shen <cnsztl@immortalwrt.org>

PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1
PKG_BUILD_FLAGS:=no-mips16

GO_PKG:=github.com/1715173329/gowebdav

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk

define Package/gowebdav
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=File Transfer
  TITLE:=A simple WebDav server written in Go
  URL:=https://github.com/1715173329/gowebdav
  DEPENDS:=$(GO_ARCH_DEPENDS)
endef

define Package/gowebdav/conffiles
/etc/config/gowebdav
endef

define Package/gowebdav/install
	$(call GoPackage/Package/Install/Bin,$(1))

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) $(CURDIR)/files/gowebdav.config $(1)/etc/config/gowebdav
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(CURDIR)/files/gowebdav.init $(1)/etc/init.d/gowebdav
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) $(CURDIR)/files/gowebdav-migrate-config.sh $(1)/etc/uci-defaults/90-gowebdav-migrate-config
endef

$(eval $(call GoBinPackage,gowebdav))
$(eval $(call BuildPackage,gowebdav))
