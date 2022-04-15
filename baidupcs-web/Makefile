# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2022 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=baidupcs-web
PKG_VERSION:=3.7.4-nnew
PKG_RELEASE:=$(AUTORELEASE)

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/Erope/BaiduPCS-Go/tar.gz/v$(PKG_VERSION)?
PKG_HASH:=6efd1c5e4cf5cf876204bed246c70ea0212ad078d4eb7703d7f1179b39551d1d
PKG_BUILD_DIR:=$(BUILD_DIR)/BaiduPCS-Go-$(PKG_VERSION)

PKG_LICENSE:=Apache-2.0
PKG_LICENSE_FILES:=LICENSE

PKG_BUILD_DEPENDS:=golang/host go-rice/host
PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

GO_PKG:=github.com/Erope/BaiduPCS-Go
GO_PKG_LDFLAGS_X:=main.Version=v$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk
include ../../lang/golang/golang-package.mk

define Package/baidupcs-web
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Download Manager
  TITLE:=A web controller for BaiduPCS-Go
  URL:=https://github.com/Erope/BaiduPCS-Go
  DEPENDS:=$(GO_ARCH_DEPENDS) +ca-bundle
endef

define Build/Compile
	( \
		pushd "$(PKG_BUILD_DIR)/internal/pcsweb" ; \
		rice embed-go ; \
		popd ; \
		$(call GoPackage/Build/Compile) ; \
	)
endef

define Package/baidupcs-web/install
	$(call GoPackage/Package/Install/Bin,$(PKG_INSTALL_DIR))

	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(GO_PKG_BUILD_BIN_DIR)/BaiduPCS-Go $(1)/usr/bin/baidupcs-web
endef

$(eval $(call GoBinPackage,baidupcs-web))
$(eval $(call BuildPackage,baidupcs-web))
