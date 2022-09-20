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
PKG_VERSION:=v2.24.12
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/uugamebooster
  SECTION:=net
  CATEGORY:=Network
  DEPENDS:=@(aarch64||arm||mipsel||x86_64) +kmod-tun
  TITLE:=NetEase UU Game Booster
  URL:=https://uu.163.com
endef

define Package/uugamebooster/description
  NetEase's UU Game Booster Accelerates Triple-A Gameplay and Market
endef

ifeq ($(ARCH),arm)
	UU_ARCH:=arm
	PKG_MD5SUM:=5926cf8c18aca92f8a6304c47739c226
endif

ifeq ($(ARCH),aarch64)
	UU_ARCH:=aarch64
	PKG_MD5SUM:=8a08b04960e7428d08cb13d8f9aaf962
endif

ifeq ($(ARCH),mipsel)
	UU_ARCH:=mipsel
	PKG_MD5SUM:=b878586944e92ea94ba57c45b063e80b
endif

ifeq ($(ARCH),x86_64)
	UU_ARCH:=x86_64
	PKG_MD5SUM:=78786fc3bc9bd411a908ddc527c35d21
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
