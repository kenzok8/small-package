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
PKG_VERSION:=v6.3.10
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
	PKG_MD5SUM:=633596a922256c2a5f8d9373620ea439
endif

ifeq ($(ARCH),aarch64)
	UU_ARCH:=aarch64
	PKG_MD5SUM:=94538a4f40dca41f508a0a9cb5958163
endif

ifeq ($(ARCH),mipsel)
	UU_ARCH:=mipsel
	PKG_MD5SUM:=022c616f84bd1ed5466eb00193376ad5
endif

ifeq ($(ARCH),x86_64)
	UU_ARCH:=x86_64
	PKG_MD5SUM:=17fb275fe666ec3d03ba3b41c2441156
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
