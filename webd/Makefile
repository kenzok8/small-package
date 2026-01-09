include $(TOPDIR)/rules.mk

PKG_NAME:=webd
PKG_RELEASE:=1

PKG_VERSION:=20240223
PKG_VERSION_MEDIATEK_FILO:=20240710

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=A Lightweight self-hosted netdisk application
	URL:=https://webd.cf
endef

TARGET_LIBC:=musl
ifeq ($(CONFIG_USE_UCLIBC),y)
  TARGET_LIBC:=uclibc
endif

ARM_LIBC_TAG:=muslgnueabi
ifeq ($(CONFIG_USE_UCLIBC),y)
  ARM_LIBC_TAG:=uclibcgnueabi
endif

TARGET_ARCH:=
TARGET_BOARD:=

ifeq ($(ARCH),x86_64)
  TARGET_ARCH:=x86_64
  TARGET_BOARD:=musl
endif

ifeq ($(ARCH),mipsel)
  TARGET_ARCH:=mipsel
  ifeq ($(BOARD),ramips)
    TARGET_BOARD:=$(TARGET_LIBC).ramips-mt7620
  endif
  ifeq ($(BOARD),bcm47xx)
    TARGET_BOARD:=musl.brcm47xx-mips74k
  endif
endif

ifeq ($(ARCH),mips)
  TARGET_ARCH:=mips
  ifeq ($(BOARD),ath79)
    TARGET_BOARD:=musl.ath79
  endif
  ifeq ($(BOARD),ar71xx)
    TARGET_BOARD:=uclibc.ar71xx
  endif
  ifeq ($(BOARD),bcm63xx)
    TARGET_BOARD:=uclibc.brcm63xx
  endif
endif

ifeq ($(ARCH),arm)
  TARGET_ARCH:=arm
  ifeq ($(BOARD),ipq806x)
    TARGET_BOARD:=$(ARM_LIBC_TAG).ipq806x
  endif
  ifeq ($(BOARD),ipq40xx)
    TARGET_BOARD:=$(ARM_LIBC_TAG).ipq40xx
  endif
  ifeq ($(BOARD),bcm53xx)
    TARGET_BOARD:=$(ARM_LIBC_TAG).bcm53xx
  endif
  ifeq ($(BOARD),oxnas)
    TARGET_BOARD:=$(ARM_LIBC_TAG).oxnas
  endif
  ifeq ($(BOARD),kirkwood)
    TARGET_BOARD:=$(ARM_LIBC_TAG).kirkwood
  endif
  ifeq ($(BOARD),mvebu)
    TARGET_BOARD:=$(ARM_LIBC_TAG).mvebu-cortexa9
  endif
endif

ifeq ($(ARCH),aarch64)
  TARGET_ARCH:=aarch64

  ifeq ($(BOARD),rockchip)
    TARGET_BOARD:=musl.rockchip-armv8
  endif
  ifeq ($(BOARD),brcm2708)
    TARGET_BOARD:=musl.brcm2708-bcm2710
  endif

  ifeq ($(BOARD),mediatek)
    ifneq (,$(filter filogic,$(SUBTARGET)))
      TARGET_BOARD:=musl.mediatek-filogic
      PKG_VERSION:=$(PKG_VERSION_MEDIATEK_FILO)
    endif
  endif
endif

ifeq ($(strip $(TARGET_ARCH)$(TARGET_BOARD)),)
  $(error Unsupported ARCH/BOARD combo: ARCH=$(ARCH) BOARD=$(BOARD) SUBTARGET=$(SUBTARGET))
endif

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(TARGET_ARCH)-openwrt-linux-$(TARGET_BOARD).tar.gz
PKG_SOURCE_URL:=https://webd.cf/webd/$(PKG_VERSION)/
PKG_HASH:=skip

UNTAR_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

define Build/Prepare
	$(INSTALL_DIR) $(UNTAR_DIR)
	$(TAR) -C $(UNTAR_DIR) -xzf $(DL_DIR)/$(PKG_SOURCE)
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(UNTAR_DIR)/webd/webd $(1)/usr/bin/webd

	$(INSTALL_DIR) $(1)/usr/share/$(PKG_NAME)/web
	$(CP) -r $(UNTAR_DIR)/webd/web/* $(1)/usr/share/$(PKG_NAME)/web/

	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_DATA) $(UNTAR_DIR)/webd/webd.conf $(1)/etc/webd.conf.example

endef

$(eval $(call BuildPackage,$(PKG_NAME)))
