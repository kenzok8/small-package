#
# Copyright (C) 2017-2024
#
# This is free software, licensed under the GNU General Public License v2.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=clouddrive2
PKG_VERSION:=0.9.8
PKG_RELEASE=1

ifeq ($(ARCH),aarch64)
	PKG_ARCH:=aarch64
	PKG_HASH:=1a3474ccb18bbdf64931082af47ab7350a7b63c4125d4e245bd71421ee4cc723
else ifeq ($(ARCH),arm)
	PKG_ARCH:=armv7
	PKG_HASH:=4de812b50a90006f62416d417f32f5abaa2ebca4a1297d5c4e74b8f9f837e8ae
else ifeq ($(ARCH),x86_64)
	PKG_ARCH:=x86_64
	PKG_HASH:=7656b5329f9fad5d76bfe3a4189c307137d4291716cb8eed5d8c7a9d6a473219
endif

include $(INCLUDE_DIR)/package.mk

define Package/clouddrive2
  SECTION:=net
  CATEGORY:=Network
  DEPENDS:=@(arm||aarch64||x86_64) +fuse-utils
  TITLE:=CloudDrive2
endef

define Package/clouddrive2/description
  CloudDrive2 is a cloud storage mounting tool for OpenWrt.
endef

PKG_SOURCE:=clouddrive-2-linux-$(PKG_ARCH)-$(PKG_VERSION).tgz
PKG_SOURCE_URL:=https://github.com/cloud-fs/cloud-fs.github.io/releases/download/v$(PKG_VERSION)

define Build/Prepare
	$(call Build/Prepare/Default)
	tar -xzvf $(DL_DIR)/clouddrive-2-linux-$(PKG_ARCH)-$(PKG_VERSION).tgz -C $(PKG_BUILD_DIR)/ --strip-components=1
endef

define Build/Compile
endef

define Package/clouddrive2/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(CURDIR)/files/clouddrive2.init $(1)/etc/init.d/clouddrive2
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) $(CURDIR)/files/clouddrive2.config $(1)/etc/config/clouddrive2
	$(INSTALL_DIR) $(1)/usr/share/clouddrive2
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/clouddrive-2-linux-$(PKG_ARCH)-$(PKG_VERSION)/clouddrive $(1)/usr/share/clouddrive2/
	cp -rf $(PKG_BUILD_DIR)/clouddrive-2-linux-$(PKG_ARCH)-$(PKG_VERSION)/wwwroot $(1)/usr/share/clouddrive2/
endef

$(eval $(call BuildPackage,clouddrive2))
