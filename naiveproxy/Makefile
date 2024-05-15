# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=naiveproxy
PKG_VERSION:=125.0.6422.35-1
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
  PKG_HASH:=829e033c930645730e39529a7be54bde571d43d3ca01ad5f8a6c58749db34308
else ifeq ($(ARCH_PACKAGES),aarch64_cortex-a72)
  PKG_HASH:=f32ce43b362aa6ceb2f24a5a8ec5c6190722b06b5a2c97ca6fddc6cfa76202cd
else ifeq ($(ARCH_PACKAGES),aarch64_generic)
  PKG_HASH:=702dc4bb621d7a8189482f49d12d8d4943dbdfffe2c7c197bbe32f8f9c0f4ee0
else ifeq ($(ARCH_PACKAGES),arm_arm1176jzf-s_vfp)
  PKG_HASH:=d14931ec0a312f8fd996c14ae1ec012a5f9e03d92139509f5edd3f19feba40d4
else ifeq ($(ARCH_PACKAGES),arm_arm926ej-s)
  PKG_HASH:=bd8f45efa94ab89a8af08b48523a9a4a21cf954261123d5c73ea57246c29d611
else ifeq ($(ARCH_PACKAGES),arm_cortex-a15_neon-vfpv4)
  PKG_HASH:=790e264c4798031781eea07360906e86494a95f4bf7466e5d34735adc5b3842a
else ifeq ($(ARCH_PACKAGES),arm_cortex-a5_vfpv4)
  PKG_HASH:=11f585c0896236343f400f1d31e2aec7a91948f0d0f55c095264a05bbb93771a
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7)
  PKG_HASH:=dc40da97ca7d7a24aa45e8520611c6f0dcb324b4326bc03051db12d50dcb4c35
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_neon-vfpv4)
  PKG_HASH:=282ca2cd3dc567a99da67bca9927180ef7147cc89249f43f0359c030fbcdcc55
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_vfpv4)
  PKG_HASH:=c0987d38af34aae4687868625591a71d59b36906f2e453e7db458addebc594f1
else ifeq ($(ARCH_PACKAGES),arm_cortex-a8_vfpv3)
  PKG_HASH:=ce7a23164af8720d71fff998ead2f0279792ede5fdb9b0cc54af05d77215af43
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9)
  PKG_HASH:=95af8607ce6302f62ff8c8b5ccf37c89d6c9b6a588249fb14a3120d1aab5c97e
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_neon)
  PKG_HASH:=9875ca3884cbcf1704ea44900fc5c89f62502ed76a7c79137d1ff3c32e912988
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_vfpv3-d16)
  PKG_HASH:=072c9ebbcbaeedd8f7fa5d3da5733460bbb7047895f5f087356de34dd5014d7a
else ifeq ($(ARCH_PACKAGES),arm_mpcore)
  PKG_HASH:=7cebee26ac672b12f4b6f7d8fd06d251c52ed75ead434f0a54c377eca4f2797d
else ifeq ($(ARCH_PACKAGES),arm_xscale)
  PKG_HASH:=92237ec96e598c2b508b8793cf1574172a4362b64b8fd9ad505bd3c3e86b8bb6
else ifeq ($(ARCH_PACKAGES),mipsel_24kc)
  PKG_HASH:=3e9cc1282a67c7487595f437a2d1a07ccf94c822ecd63086227a2d6b699a71d5
else ifeq ($(ARCH_PACKAGES),mipsel_mips32)
  PKG_HASH:=0aa2920f09f10c60d292b809a571e562df8cf83f8ea86281457f2d06ad466533
else ifeq ($(ARCH_PACKAGES),riscv64)
  PKG_HASH:=8cae7646c9cc4e99b33b2f4de65795ebeb6eb7744e9babc39e6357180eb3bfb0
else ifeq ($(ARCH_PACKAGES),x86)
  PKG_HASH:=21d83d8217ab3de9d41443530e7d2a34cc3a0b0395da881b1b210209bea601c6
else ifeq ($(ARCH_PACKAGES),x86_64)
  PKG_HASH:=c39f4334f1ca292febd31fa153ed662f4cfea241183cb5ee97da2ca731d7ae9e
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
