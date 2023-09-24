#
# Copyright (C) 2021 KFERMercer <KFER.Mercer@gmail.com>
#
# This is free software, licensed under the GNU General Public License v3.
#

#
# to get the latest version & md5 checksum:
# curl -L -s -k -H "Accept:text/plain" "http://router.uu.163.com/api/plugin?type=openwrt-$(UU_ARCH)"
#

include $(TOPDIR)/rules.mk

PKG_NAME:=uugamebooster
PKG_VERSION:=3.15.0
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(ARCH).tar.gz
PKG_SOURCE_URL:=https://uu.gdl.netease.com/uuplugin/openwrt-$(ARCH)/v$(PKG_VERSION)/uu.tar.gz?
ifeq ($(ARCH),aarch64)
  PKG_HASH:=4200ea60177a3cc427e2e3c1bbff318551fc2ddbf0fcabd85a9be139e3a947db
else ifeq ($(ARCH),arm)
  PKG_HASH:=5fc9aa0219ce1e4518d0db0bfbe88779cbf42c5cea57ed8799b34fa7a3afa1d5
else ifeq ($(ARCH),mipsel)
  PKG_HASH:=40fc0e47b40379c6264e24e83d40e41bf566812b80b0561ba3a4b4187973e11b
else ifeq ($(ARCH),x86_64)
  PKG_HASH:=7132328abc3cde3bb0201ff39cb209c128182ce8b27ba2f4c01355d0e67b4912
endif

define Package/uugamebooster/description
  NetEase's UU Game Booster Accelerates Triple-A Gameplay and Market
endef

ifeq ($(ARCH),arm)
	UU_ARCH:=arm
	PKG_MD5SUM:=d9687105b1cce30f2d2cc971251ae0a2
endif

ifeq ($(ARCH),aarch64)
	UU_ARCH:=aarch64
	PKG_MD5SUM:=7b5b49364da31459fb4293a312021ab3
endif

ifeq ($(ARCH),mipsel)
	UU_ARCH:=mipsel
	PKG_MD5SUM:=6aca5ecec753c199fe80bcc176fe6212
endif

ifeq ($(ARCH),x86_64)
	UU_ARCH:=x86_64
	PKG_MD5SUM:=857fa8cd2a7e9dba03db88f834cac40e
endif

PKG_SOURCE_URL:=https://uu.gdl.netease.com/uuplugin/openwrt-$(UU_ARCH)/$(PKG_VERSION)/uu.tar.gz?
PKG_SOURCE:=$(PKG_NAME)-$(UU_ARCH)-$(PKG_VERSION).tar.gz

STRIP:=true

UNTAR_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)/$(PKG_NAME)-$(UU_ARCH)-bin

define Build/Prepare
	mkdir -vp $(UNTAR_DIR)
	tar -zxvf $(DL_DIR)/$(PKG_SOURCE) -C $(UNTAR_DIR)
endef

define Build/Compile
endef

define Package/uugamebooster/conffiles
/root/.uuplugin_uuid
endef

define Package/uugamebooster/install
	# $(INSTALL_DIR) $(1)/etc/init.d
	# $(INSTALL_BIN) ./files/uugamebooster.init $(1)/etc/init.d/uuplugin

	$(INSTALL_DIR) $(1)/usr/share/uugamebooster
	$(INSTALL_BIN) $(UNTAR_DIR)/uuplugin $(1)/usr/share/uugamebooster/uuplugin
	$(INSTALL_CONF) $(UNTAR_DIR)/uu.conf $(1)/usr/share/uugamebooster/uu.conf

	# not finish yet:
	# $(INSTALL_DIR) $(1)/usr/bin
	# $(INSTALL_BIN) ./files/uugamebooster-update $(1)/usr/bin/uugamebooster
	# $(LN) $(1)/usr/bin/uugamebooster/uugamebooster-update $(1)/usr/bin/uugamebooster-update
endef

$(eval $(call BuildPackage,uugamebooster))
