#
# Copyright (C) 2026 jjm2473@gmail.com
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

MISE_ARCH_x86_64:=x64
MISE_ARCH_aarch64:=arm64
MISE_ARCH:=$(MISE_ARCH_$(ARCH))

MISE_HASH_x86_64:=3832f39c325e343f81fe3d92b2447c5d1a5eea1bc85092bb7b6c25806222647e
MISE_HASH_aarch64:=06186cfbfe947049b21d58575fb0ea800cc26ed1375f20f4b678cb3a9d679437

PKG_NAME:=mise
PKG_VERSION:=2026.8.14
PKG_RELEASE:=1
PKG_SOURCE:=$(PKG_NAME)-v$(PKG_VERSION)-linux-$(MISE_ARCH)-musl.tar.gz
PKG_SOURCE_URL:=https://github.com/jdx/mise/releases/download/v$(PKG_VERSION)/
PKG_HASH:=$(MISE_HASH_$(ARCH))
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=utils
	CATEGORY:=Utilities
	TITLE:=mise - polyglot tool version manager
	DEPENDS:=@(x86_64||aarch64)
	URL:=https://mise.jdx.dev
endef

define Package/$(PKG_NAME)/description
  mise manages development tool versions, environment variables, and tasks.
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/mise $(1)/usr/bin/mise
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
