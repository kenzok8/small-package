# SPDX-License-Identifier: GPL-2.0
#
# Copyright (C) 2024-2026 Anya Lin <hukk1996@gmail.com>

include $(TOPDIR)/rules.mk

PKG_NAME:=mihomo
PKG_VERSION:=1.19.19
PKG_RELEASE:=2

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/metacubex/mihomo/tar.gz/v$(PKG_VERSION)?
PKG_HASH:=3e0f06ecf84671d30ac5d6eff840c120d074fe802263738f053c4c34257d0dc0

PKG_MAINTAINER:=Anya Lin <hukk1996@gmail.com>
PKG_LICENSE:=GPL-2.0
PKG_LICENSE_FILES:=LICENSE

PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1
PKG_BUILD_FLAGS:=no-mips16

GO_PKG:=github.com/metacubex/mihomo

PKG_BUILD_TIME:=$(shell date -u +%FT%TZ%z)
GO_PKG_LDFLAGS_X:=\
	$(GO_PKG)/constant.Version=v$(PKG_VERSION) \
	$(GO_PKG)/constant.BuildTime=$(PKG_BUILD_TIME)
GO_PKG_TAGS:=with_gvisor

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk

define Package/mihomo
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Another Mihomo Kernel.
  URL:=https://wiki.metacubex.one
  DEPENDS:=$(GO_ARCH_DEPENDS)
  PROVIDES:=mihomo
  ALTERNATIVES:=\
    100:/usr/bin/mihomo:/usr/libexec/mihomo-core
  USERID:=mihomo=7890:mihomo=7890
endef

define Build/Prepare
	$(Build/Prepare/Default)
	# rm unit test
	rm -f $(PKG_BUILD_DIR)/rules/logic_test/logic_test.go
endef

define Package/mihomo/install
	$(call GoPackage/Package/Install/Bin,$(PKG_INSTALL_DIR))
	$(CURDIR)/.prepare.sh $(VERSION) $(CURDIR) $(PKG_INSTALL_DIR)/usr/bin/$(PKG_NAME)

	$(INSTALL_DIR) $(1)/usr/libexec/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/$(PKG_NAME) $(1)/usr/libexec/mihomo-core
endef

$(eval $(call GoBinPackage,mihomo))
$(eval $(call BuildPackage,mihomo))
