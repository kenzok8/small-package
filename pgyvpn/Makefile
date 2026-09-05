include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/target.mk

ifeq ($(ARCH),arm)
  ifneq ($(findstring $(CPU_SUBTYPE), neon neon-vfpv4 vfpv3),)
	PKG_ARCH_PGYYPN:=arm_$(CPU_TYPE)_$(CPU_SUBTYPE)-$(LIBC)-unknown
  else ifneq ($(findstring $(CPU_TYPE), cortex-a9),)
	PKG_ARCH_PGYYPN:=arm_cortex-a9-$(LIBC)-unknown
  else
	PKG_ARCH_PGYYPN:=arm_cortex-a7-$(LIBC)-unknown
  endif
endif
ifeq ($(ARCH),aarch64)
  ifneq ($(findstring $(CPU_TYPE), cortex-a53 cortex-a72),)
	PKG_ARCH_PGYYPN:=aarch64_$(CPU_TYPE)-$(LIBC)-unknown
  else
	PKG_ARCH_PGYYPN:=aarch64_generic-$(LIBC)-unknown
  endif
endif
ifeq ($(ARCH),mips)
	PKG_ARCH_PGYYPN:=mips_24kc-$(LIBC)-unknown
endif
ifeq ($(ARCH),mipsel)
  ifneq ($(findstring $(CPU_TYPE), 24kec 74kc 1004kc),)
	PKG_ARCH_PGYYPN:=$(ARCH)_$(CPU_TYPE)-$(LIBC)-unknown
  else
	PKG_ARCH_PGYYPN:=mipsel_24kc-$(LIBC)-unknown
  endif
endif
ifeq ($(BOARD),x86)
  ifeq ($(ARCH),x86_64)
	PKG_ARCH_PGYYPN:=x86_64-$(LIBC)-unknown
  else
	PKG_ARCH_PGYYPN:=i386_pentium-mmx-$(LIBC)-unknown
  endif
endif

PKG_NAME:=pgyvpn
PKG_VERSION:=3.1.0
PKG_RELEASE:=2

PKG_SOURCE:=pgyvpnsvr
PKG_SOURCE_URL:=https://mirrors.oray.com/orayos/packages/$(PKG_NAME)/$(PKG_ARCH_PGYYPN)/$(PKG_VERSION)/bin
PKG_HASH:=skip

OPENSSL_COMPAT_VERSION:=1.1.1w
OPENSSL_COMPAT_SOURCE:=openssl-$(OPENSSL_COMPAT_VERSION).tar.gz
OPENSSL_COMPAT_HASH:=cf3098950cb4d853ad95c0841f1f9c6d3dc102dccfcacd521d93925208b76ac8

OPENSSL_COMPAT_TARGET:=linux-generic32
ifeq ($(ARCH),arm)
	OPENSSL_COMPAT_TARGET:=linux-armv4
endif
ifeq ($(ARCH),aarch64)
	OPENSSL_COMPAT_TARGET:=linux-aarch64
endif
ifeq ($(ARCH),mips)
	OPENSSL_COMPAT_TARGET:=linux-mips32
endif
ifeq ($(ARCH),mipsel)
	OPENSSL_COMPAT_TARGET:=linux-mips32
endif
ifeq ($(ARCH),i386)
	OPENSSL_COMPAT_TARGET:=linux-x86
endif
ifeq ($(ARCH),x86_64)
	OPENSSL_COMPAT_TARGET:=linux-x86_64
endif

PKG_MAINTAINER:=Oray <developer@oray.com>

include $(INCLUDE_DIR)/package.mk

define Package/pgyvpn
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=VPN
  DEPENDS:=@(arm||aarch64||mips||mipsel||i386||x86_64) \
	+iptables +libc +librt \
	+libpthread +libstdcpp +kmod-tun
  TITLE:=PuGongYing VPN, Fast networking
  URL:=https://pgy.oray.com/
endef

define Package/pgyvpn/description
  PuGongYing VPN is a product of Oray Company, support custom network, account security
  system, traffic monitoring, cloud application access, virtual serial port, etc.
endef

define Download/extra
  FILE:=pgyvpn_oraysl
  URL:=$(PKG_SOURCE_URL)
  HASH:=skip
endef

define Download/openssl-compat
  FILE:=$(OPENSSL_COMPAT_SOURCE)
  URL:=https://www.openssl.org/source/old/1.1.1
  HASH:=$(OPENSSL_COMPAT_HASH)
endef
$(eval $(call Download,extra))
$(eval $(call Download,openssl-compat))

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(TAR) -C $(PKG_BUILD_DIR) -xf $(DL_DIR)/$(OPENSSL_COMPAT_SOURCE)
	mv $(DL_DIR)/{pgyvpn_oraysl,pgyvpnsvr} $(PKG_BUILD_DIR)
	chmod +x $(PKG_BUILD_DIR)/{pgyvpn_oraysl,pgyvpnsvr}
endef

define Build/Configure
	( cd $(PKG_BUILD_DIR)/openssl-$(OPENSSL_COMPAT_VERSION) && \
		CC="$(TARGET_CC)" \
		./Configure $(OPENSSL_COMPAT_TARGET) \
			--prefix=/usr \
			--libdir=lib \
			--cross-compile-prefix="$(TARGET_CROSS)" \
			shared no-tests no-engine no-async no-comp no-asm \
			$(TARGET_CFLAGS) $(TARGET_CPPFLAGS) $(TARGET_LDFLAGS) \
	)
endef

define Build/Compile
	+$(MAKE) $(PKG_JOBS) -C $(PKG_BUILD_DIR)/openssl-$(OPENSSL_COMPAT_VERSION) \
		CC="$(TARGET_CC)" \
		SOURCE_DATE_EPOCH=$(SOURCE_DATE_EPOCH) \
		build_libs
endef

define Package/pgyvpn/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_DIR) $(1)/usr/share/pgyvpn
	$(INSTALL_DIR) $(1)/usr/lib

	$(CP) $(PKG_BUILD_DIR)/{pgyvpn_oraysl,pgyvpnsvr} $(1)/usr/sbin
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/openssl-$(OPENSSL_COMPAT_VERSION)/libssl.so.1.1 $(1)/usr/lib
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/openssl-$(OPENSSL_COMPAT_VERSION)/libcrypto.so.1.1 $(1)/usr/lib
	$(INSTALL_BIN) ./files/etc/init.d/* $(1)/etc/init.d
	$(INSTALL_CONF) ./files/etc/config/* $(1)/etc/config
	$(INSTALL_BIN) ./files/etc/hotplug.d/iface/* $(1)/etc/hotplug.d/iface
	$(INSTALL_BIN) ./files/usr/share/pgyvpn/* $(1)/usr/share/pgyvpn
endef

define Package/pgyvpn/preinst
	#!/bin/sh
	[ -z "$${IPKG_INSTROOT}" ] && {
		pidof pgyvpnsvr > /dev/null && \
			test -f $${PKG_ROOT}etc/init.d/pgyvpn && \
				/etc/init.d/pgyvpn stop; true
	}
	exit 0
endef

define Package/pgyvpn/postinst
	#!/bin/sh
	[ -z "$${IPKG_INSTROOT}" ] && {
		/etc/init.d/pgyvpn restart; true
	}
	exit 0
endef

$(eval $(call BuildPackage,pgyvpn))
