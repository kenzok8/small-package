include $(TOPDIR)/rules.mk

PKG_NAME:=shadowsocksr-libev
PKG_VERSION:=2.5.3
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/shadowsocksrr/shadowsocksr-libev/tar.gz/$(PKG_VERSION)?
PKG_HASH:=3fc11a0a132aa6f229285f459e8ce391c20bf86b731b757b0de4dbc96c12301c

PKG_LICENSE:=GPL-3.0
PKG_LICENSE_FILES:=LICENSE

PKG_FIXUP:=autoreconf
PKG_USE_MIPS16:=0
PKG_BUILD_FLAGS:=no-mips16
PKG_BUILD_PARALLEL:=1
PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

define Package/shadowsocksr-libev/Default
  define Package/shadowsocksr-libev-ssr-$(1)
    SECTION:=net
    CATEGORY:=Network
    SUBMENU:=Web Servers/Proxies
    TITLE:=shadowsocksr-libev ssr-$(1)
    URL:=https://github.com/shadowsocksrr/shadowsocksr-libev
    DEPENDS:=+libev +libsodium +libopenssl +libpthread +libpcre +libudns +zlib +libopenssl-legacy
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

CONFIGURE_ARGS += \
	--disable-documentation \
	--disable-ssp \
	--disable-assert \
	--enable-system-shared-lib

TARGET_CFLAGS += -flto
TARGET_LDFLAGS += -Wl,--gc-sections,--as-needed

ifeq ($(CONFIG_GCC_VERSION_12),y)
	TARGET_CFLAGS += -Wno-error=use-after-free
endif

ifeq ($(CONFIG_GCC_VERSION_13),y)
	TARGET_CFLAGS += -Wno-error=use-after-free
endif

$(foreach component,$(SHADOWSOCKSR_COMPONENTS), \
  $(eval $(call BuildPackage,shadowsocksr-libev-ssr-$(component))) \
)
