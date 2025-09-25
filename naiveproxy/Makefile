# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=naiveproxy
PKG_VERSION:=140.0.7339.123-2
PKG_RELEASE:=1

# intel 80386 & riscv64 & cortex-a76
ifeq ($(ARCH_PREBUILT),aarch64_cortex-a76)
  ARCH_PREBUILT:=aarch64_generic
else ifeq ($(ARCH_PREBUILT),i386_pentium-mmx)
  ARCH_PREBUILT:=x86
else ifeq ($(ARCH_PREBUILT),i386_pentium4)
  ARCH_PREBUILT:=x86
else ifeq ($(ARCH_PREBUILT),riscv64_riscv64)
  ARCH_PREBUILT:=riscv64
endif

ifeq ($(ARCH_PACKAGES),aarch64_cortex-a53)
  PKG_HASH:=d645cf81ffef1e56c772553761fd34ed646da5de55b2084c8d25bc5a5f3a2e8e
else ifeq ($(ARCH_PACKAGES),aarch64_cortex-a72)
  PKG_HASH:=b4d31db433ff3b1e28b0a2d0393317b815a41bdaa69f841516086dcfa4ac52bb
else ifeq ($(ARCH_PACKAGES),aarch64_generic)
  PKG_HASH:=eccb7341e5a2a2307e2c7b469adb271fcb76c9b7d96428b5d9216eb91f07bc04
else ifeq ($(ARCH_PACKAGES),arm_arm1176jzf-s_vfp)
  PKG_HASH:=c90c564d09648ef7f7b83595b8a0a4635ea8b293c4bfb3ac432d0cc5d003719e
else ifeq ($(ARCH_PACKAGES),arm_arm926ej-s)
  PKG_HASH:=e6b0f057b719fffd3bc5f201538767c69e6367a1e1480808efe62d4f093e4b55
else ifeq ($(ARCH_PACKAGES),arm_cortex-a15_neon-vfpv4)
  PKG_HASH:=4e41da71ed4a588d9da6748857b7063f441275d573c8935b24b41adad6f92136
else ifeq ($(ARCH_PACKAGES),arm_cortex-a5_vfpv4)
  PKG_HASH:=3f6b4544f26bfde40ab4028d2b646e6ef98dfff1c7606296786e9aa216ad8fa2
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7)
  PKG_HASH:=852822d17e41a0bccd7487a064af19cb8347b43cccae7d2861d6c69fe1b9decf
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_neon-vfpv4)
  PKG_HASH:=a374076612e4ee741c60d57173771bb6b6f2a2710d4d9a637afb6e8ddce98e76
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_vfpv4)
  PKG_HASH:=0b335809706c8ecbd1a6680adad7f74a0877b74496d11a556dbe6ccb7ab3e7a4
else ifeq ($(ARCH_PACKAGES),arm_cortex-a8_vfpv3)
  PKG_HASH:=12cf7be62a5d5fd5c0e886e1a22db445b9ef5f34728c1c788e8a8632ae0105a9
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9)
  PKG_HASH:=9977f8a2c023caa4d7a50b8e4f721f9de18879b74f246c050ea2b15b57e6ff3b
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_neon)
  PKG_HASH:=d72fd69a5a67ee38c066dbed077f93949b2224ea0a5b45271ef60aac838acb31
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_vfpv3-d16)
  PKG_HASH:=3092b1a38b437aef76bbfee69d9a17fcf862907015ef1083e8b2695bfed92723
else ifeq ($(ARCH_PACKAGES),arm_mpcore)
  PKG_HASH:=3ad1361dac50779702821199615b608b4f152dead1d6413f6da812474767c880
else ifeq ($(ARCH_PACKAGES),arm_xscale)
  PKG_HASH:=2758f4bc0c52542db66f777579bc22a19f6538936b7d139d811c0b89f5305b8f
else ifeq ($(ARCH_PACKAGES),mipsel_24kc)
  PKG_HASH:=fda6d212bbd8f364955276dac1703e0f9b99c7b5e068211e6cf70c1a4ed68a6f
else ifeq ($(ARCH_PACKAGES),mipsel_mips32)
  PKG_HASH:=076d6a3d747f55678bc8e95a2842338b05fcdcc58ae371a40c4a112601d5b5d3
else ifeq ($(ARCH_PACKAGES),riscv64)
  PKG_HASH:=7c9dac91d9531ea58333d3d966016b8dfd5bcc3d563de8b562c360389804b08d
else ifeq ($(ARCH_PACKAGES),x86)
  PKG_HASH:=d8dfba54bebd124a2a43eca8abfaf6cf98568eac2bd0506be196e36fcf2cb27c
else ifeq ($(ARCH_PACKAGES),x86_64)
  PKG_HASH:=5903794ae52b3f9f249dfd825c78235087f4253c528fbe60085d025cf5fb791a
else
  PKG_HASH:=dummy
endif

PKG_SOURCE:=naiveproxy-v$(PKG_VERSION)-openwrt-$(ARCH_PACKAGES).tar.xz
PKG_SOURCE_URL:=https://github.com/klzgrad/naiveproxy/releases/download/v$(PKG_VERSION)/
PKG_BUILD_DIR:=$(BUILD_DIR)/naiveproxy-v$(PKG_VERSION)-openwrt-$(ARCH_PACKAGES)

PKG_LICENSE:=BSD 3-Clause
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=sbwml <admin@cooluc.com>

include $(INCLUDE_DIR)/package.mk

define Package/naiveproxy
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  TITLE:=Make a fortune quietly
  URL:=https://github.com/klzgrad/naiveproxy
  DEPENDS:=@(aarch64||arm||i386||mipsel||riscv64||x86_64) +libatomic
endef

define Package/naiveproxy/description
  NaïveProxy uses Chrome's network stack to camouflage traffic with strong
  censorship resistance and low detectability. Reusing Chrome's stack also
  ensures best practices in performance and security.
endef

define Package/naiveproxy/conffiles
/etc/config/naiveproxy
endef

define Build/Compile
endef

define Package/naiveproxy/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/naive $(1)/usr/bin/naive
	$(INSTALL_DIR) $(1)/etc/config $(1)/etc/init.d
	$(INSTALL_CONF) $(CURDIR)/files/naiveproxy.config $(1)/etc/config/naiveproxy
	$(INSTALL_BIN) $(CURDIR)/files/naiveproxy.init $(1)/etc/init.d/naiveproxy
endef

$(eval $(call BuildPackage,naiveproxy))
