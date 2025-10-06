# SDPX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021-2022 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=amule
PKG_VERSION:=2.3.3
PKG_RELEASE:=5

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/amule-project/amule/tar.gz/$(PKG_VERSION)?
PKG_HASH:=934f79d4dab41c2d1caea31d6c6e10337c409ba5bb8bd6fac6c63e924e82c9b8

PKG_CONFIG_DEPEDS:= CONFIG_AMULE_CRYPTOPP_STATIC_LINKING

PKG_FIXUP:=autoreconf
PKG_BUILD_DEPENDS:=libgd
PKG_BUILD_PARALLEL:=1
PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

define Package/amule
  SUBMENU:=P2P
  SECTION:=net
  CATEGORY:=Network
  TITLE:=A multi-platform eMule-like ed2k client
  URL:=http://www.amule.org/
  DEPENDS:=+antileech +libpng +libpthread +libncurses +libreadline +libwxbase \
	+libupnp +libbfd +libcryptopp
endef

CONFIGURE_ARGS+= \
	--disable-nls \
	--disable-static \
	--disable-rpath \
	--disable-ccache \
	--disable-profile \
	--disable-monolithic \
	--enable-amule-daemon \
	--enable-amulecmd \
	--enable-webserver \
	--disable-amule-gui \
	--disable-cas \
	--disable-wxcas \
	--disable-ed2k \
	--disable-alc \
	--disable-alcc \
	--disable-debug \
	--disable-fileview \
	--disable-plasmamule \
	--without-wxdebug \
	--enable-dlp \
	--enable-upnp \
	--enable-optimize \
	--with-gnu-ld \
	--with-zlib="$(STAGING_DIR)/usr" \
	--with-gdlib-prefix="$(STAGING_DIR)/usr" \
	--with-libpng-prefix="$(STAGING_DIR)/usr" \
	--with-wx-prefix="$(STAGING_DIR)/usr" \
	--with-crypto-prefix="$(STAGING_DIR)/usr" \
	--with-libupnp-prefix="$(STAGING_DIR)/usr" \
	--without-x

MAKE_FLAGS += HOSTCC="$(HOSTCC)"

define Build/Configure
	( cd $(PKG_BUILD_DIR); $(SHELL) autogen.sh; )
	$(call Build/Configure/Default)
endef

define Package/amule/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/amulecmd $(1)/usr/bin/amulecmd
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/amuled $(1)/usr/bin/amuled
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/amuleweb $(1)/usr/bin/amuleweb

	$(INSTALL_DIR) $(1)/usr/share
	$(CP) $(PKG_INSTALL_DIR)/usr/share/amule $(1)/usr/share/
endef

$(eval $(call BuildPackage,amule))
