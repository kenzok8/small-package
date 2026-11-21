include $(TOPDIR)/rules.mk

PKG_NAME:=shadowsocksr-libev
PKG_VERSION:=2.5.11
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/kenzok8/shadowsocksr-libev/tar.gz/v$(PKG_VERSION)?
PKG_HASH:=42796cc59a8ddbf79042af817a9c0f86a414a46d737951a37b0bc633d630c74e

PKG_LICENSE:=GPL-3.0
PKG_LICENSE_FILES:=LICENSE

PKG_USE_MIPS16:=0
PKG_BUILD_FLAGS:=no-mips16
PKG_BUILD_PARALLEL:=1
PKG_FIXUP:=autoreconf
PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

define Package/shadowsocksr-libev/Default
  define Package/shadowsocksr-libev-ssr-$(1)
    SECTION:=net
    CATEGORY:=Network
    SUBMENU:=Web Servers/Proxies
    TITLE:=shadowsocksr-libev ssr-$(1)
    URL:=https://github.com/kenzok8/shadowsocksr-libev
    DEPENDS:=+libev +libsodium +libopenssl +libpthread +libpcre2 +libudns +zlib +libopenssl-legacy
  endef

  define Package/shadowsocksr-libev-ssr-$(1)/install
	$$(INSTALL_DIR) $$(1)/usr/bin
	$$(INSTALL_BIN) $$(PKG_INSTALL_DIR)/usr/bin/ss-$(1) $$(1)/usr/bin/ssr-$(1)
  endef
endef

SHADOWSOCKSR_COMPONENTS:=check local nat redir server
define shadowsocksr-libev/templates
  $(foreach component,$(SHADOWSOCKSR_COMPONENTS),
    $(call Package/shadowsocksr-libev/Default,$(component))
  )
endef
$(eval $(call shadowsocksr-libev/templates))

define Build/Prepare
	$(call Build/Prepare/Default)
	# Patch configure: use pcre2 instead of pcre1 (OpenWrt 24.10 only provides pcre2)
	sed -i \
		-e 's/pcre-config/pcre2-config/g' \
		-e 's/PCRE_CONFIG --libs/PCRE_CONFIG --libs8/g' \
		-e 's/pcre_exec/pcre2_match_8/g' \
		-e '/for ac_lib in/{s/ pcre;/ pcre2-8;/}' \
		-e 's/pcre\.h/pcre2.h/g' \
		-e 's/pcre\/pcre\.h/pcre2\/pcre2.h/g' \
		$(PKG_BUILD_DIR)/configure
endef

define Build/Compile
	$(call Build/Compile/Default)
	$(TARGET_CC) $(TARGET_CFLAGS) -o $(PKG_BUILD_DIR)/ss-check $(CURDIR)/src/server/check.c
endef

define Build/Install
	$(call Build/Install/Default)
	$(INSTALL_DIR) $(PKG_INSTALL_DIR)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ss-check $(PKG_INSTALL_DIR)/usr/bin/ss-check
endef

CONFIGURE_ARGS += \
	--disable-documentation \
	--disable-ssp \
	--disable-assert \
	--enable-system-shared-lib \
	--with-pcre=$(STAGING_DIR)/usr

TARGET_CFLAGS += -flto
TARGET_CFLAGS += -Wno-error=use-after-free
TARGET_CPPFLAGS += -DPCRE2_CODE_UNIT_WIDTH=8
TARGET_LDFLAGS += -Wl,--gc-sections,--as-needed

$(foreach component,$(SHADOWSOCKSR_COMPONENTS), \
  $(eval $(call BuildPackage,shadowsocksr-libev-ssr-$(component))) \
)
