include $(TOPDIR)/rules.mk

PKG_NAME:=speedtest-cli
PKG_VERSION:=1.2.0
PKG_RELEASE:=1

ifeq ($(ARCH),aarch64)
  PKG_HASH:=3953d231da3783e2bf8904b6dd72767c5c6e533e163d3742fd0437affa431bd3
else ifeq ($(ARCH),arm)
  ARM_CPU_FEATURES:=$(word 2,$(subst +,$(space),$(call qstrip,$(CONFIG_CPU_TYPE))))
  ifeq ($(ARM_CPU_FEATURES),)
    ARCH:=armel
    PKG_HASH:=629a455a2879224bd0dbd4b36d8c721dda540717937e4660b4d2c966029466bf
  else
    ARCH:=armhf
    PKG_HASH:=e45fcdebbd8a185553535533dd032d6b10bc8c64eee4139b1147b9c09835d08d
  endif
else ifeq ($(ARCH),i386)
  PKG_HASH:=9ff7e18dbae7ee0e03c66108445a2fb6ceea6c86f66482e1392f55881b772fe8
else ifeq ($(ARCH),x86_64)
  PKG_HASH:=5690596c54ff9bed63fa3732f818a05dbc2db19ad36ed68f21ca5f64d5cfeeb7
endif

PKG_SOURCE:=ookla-speedtest-$(PKG_VERSION)-linux-$(ARCH).tgz
PKG_SOURCE_URL:=https://install.speedtest.net/app/cli

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

PKG_MAINTAINER:=sbwml <admin@cooluc.com>

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Speedtest CLI by Ookla
	DEPENDS:=@(aarch64||arm||i386||x86_64) +ca-certificates
	URL:=https://www.speedtest.net/
endef

define Package/$(PKG_NAME)/description
  The Global Broadband Speed Test
endef

define Build/Prepare
	( \
		pushd $(PKG_BUILD_DIR) ; \
			$(TAR) -zxf $(DL_DIR)/ookla-speedtest-$(PKG_VERSION)-linux-$(ARCH).tgz -C . ; \
		popd ; \
	)
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/speedtest $(1)/usr/bin
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
