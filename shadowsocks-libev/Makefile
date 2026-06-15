#
# Copyright (C) 2017-2020 Yousong Zhou <yszhou4tech@gmail.com>
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

# Checklist when bumping versions
#
# - update cipher list by checking src/crypto.c:crypto_init()
# - check if default mode has changed from being tcp_only
#
PKG_NAME:=shadowsocks-libev
PKG_VERSION:=3.3.6
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/shadowsocks/shadowsocks-libev.git
PKG_SOURCE_DATE:=2026-02-09
PKG_SOURCE_VERSION:=c5e8788013a37afe54ea1c2b7c03395cccc663cf
PKG_MIRROR_HASH:=96d0b486a0c8dbb2acf2af56534f6c765565c127c3695c98b5157b24993a4839

PKG_MAINTAINER:=Yousong Zhou <yszhou4tech@gmail.com>

PKG_LICENSE:=GPL-3.0-or-later
PKG_LICENSE_FILES:=LICENSE
PKG_CPE_ID:=cpe:/a:shadowsocks:shadowsocks-libev

PKG_BUILD_PARALLEL:=1
PKG_BUILD_FLAGS:=no-mips16 lto

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

CMAKE_OPTIONS += \
	-DWITH_STATIC=OFF \
	-DWITH_EMBEDDED_SRC=ON \
	-DWITH_DOC_MAN=OFF \
	-DWITH_DOC_HTML=OFF \
	-DCMAKE_BUILD_TYPE=Release \
	-DBUILD_TESTING=OFF \
	-DENABLE_CONNMARKTOS=OFF \
	-DENABLE_NFTABLES=OFF

define Package/shadowsocks-libev/Default
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  URL:=https://github.com/shadowsocks/shadowsocks-libev
  DEPENDS:=+libev +libmbedtls +libpthread +libsodium +libcares +libpcre2
endef

define Package/shadowsocks-libev-ss-local
  $(call Package/shadowsocks-libev/Default)
  TITLE:=shadowsocks-libev ss-local
endef

define Package/shadowsocks-libev-ss-redir
  $(call Package/shadowsocks-libev/Default)
  TITLE:=shadowsocks-libev ss-redir
endef

define Package/shadowsocks-libev-ss-tunnel
  $(call Package/shadowsocks-libev/Default)
  TITLE:=shadowsocks-libev ss-tunnel
endef

define Package/shadowsocks-libev-ss-server
  $(call Package/shadowsocks-libev/Default)
  TITLE:=shadowsocks-libev ss-server
endef

define Package/shadowsocks-libev-ss-local/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/ss-local $(1)/usr/bin
endef

define Package/shadowsocks-libev-ss-redir/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/ss-redir $(1)/usr/bin
endef

define Package/shadowsocks-libev-ss-tunnel/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/ss-tunnel $(1)/usr/bin
endef

define Package/shadowsocks-libev-ss-server/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/ss-server $(1)/usr/bin
endef

$(eval $(call BuildPackage,shadowsocks-libev-ss-local))
$(eval $(call BuildPackage,shadowsocks-libev-ss-redir))
$(eval $(call BuildPackage,shadowsocks-libev-ss-tunnel))
$(eval $(call BuildPackage,shadowsocks-libev-ss-server))
