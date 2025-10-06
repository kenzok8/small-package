# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2017-2020 Yousong Zhou <yszhou4tech@gmail.com>
# Copyright (C) 2021-2023 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=aliyundrive-webdav
PKG_VERSION:=2.3.2
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/messense/aliyundrive-webdav.git
PKG_SOURCE_VERSION:=7ba03f68fd5200802000997548a4a2b33b404324
PKG_MIRROR_HASH:=05826a036c266d58c784b08b59f6c948857947b78da3e76ed9847bd69a7d7d4b

PKG_LICENSE:=MIT
PKG_MAINTAINER:=messense <messense@icloud.com>

PKG_BUILD_DEPENDS:=rust/host

RUST_PKG_FEATURES:=rustls-tls atomic64 native-tls native-tls-vendored

include $(INCLUDE_DIR)/package.mk
include ../../lang/rust/rust-package.mk

define Package/aliyundrive-webdav
  SECTION:=multimedia
  CATEGORY:=Multimedia
  TITLE:=WebDAV server for AliyunDrive
  URL:=https://github.com/messense/aliyundrive-webdav
  DEPENDS:=$$(RUST_ARCH_DEPENDS)
endef

define Package/aliyundrive-webdav/description
  WebDAV server for AliyunDrive.
endef

define Package/aliyundrive-webdav/conffiles
/etc/config/aliyundrive-webdav
endef

define Package/aliyundrive-webdav/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/target/$(RUSTC_TARGET_ARCH)/release/aliyundrive-webdav $(1)/usr/bin/

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/aliyundrive-webdav.init $(1)/etc/init.d/aliyundrive-webdav
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/aliyundrive-webdav.config $(1)/etc/config/aliyundrive-webdav
endef

$(eval $(call BuildPackage,aliyundrive-webdav))
