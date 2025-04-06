# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=naiveproxy
PKG_VERSION:=135.0.7049.38-2
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
  PKG_HASH:=b8976be510c3e1de4e814cd0f0a5980efcb845473577546428b898d1bdeb079b
else ifeq ($(ARCH_PACKAGES),aarch64_cortex-a72)
  PKG_HASH:=4d0a93b889ab1b88e8f1f343c4481e42596759d4fed8b1d6041a2eb86c783500
else ifeq ($(ARCH_PACKAGES),aarch64_generic)
  PKG_HASH:=77ffe91387a29aaac22433b71c06bac3dcd28aad31ef3697e443a89bc8714c16
else ifeq ($(ARCH_PACKAGES),arm_arm1176jzf-s_vfp)
  PKG_HASH:=cb6ae58df88efcae821fff18327e660e4590761a09a4ab9e34cdc297b67884e6
else ifeq ($(ARCH_PACKAGES),arm_arm926ej-s)
  PKG_HASH:=129dc86a2eb9fd1d5421098795ffd534248a02a9ca1f4436e9f052960d52da0f
else ifeq ($(ARCH_PACKAGES),arm_cortex-a15_neon-vfpv4)
  PKG_HASH:=d0560697e7457bbd10e5e08421c49d554c8e4b6ca1f522a467093a791f9bee17
else ifeq ($(ARCH_PACKAGES),arm_cortex-a5_vfpv4)
  PKG_HASH:=8e1caa8f57c954942fbf37cb237392b59ca966f261d697d7ba08be313da4501b
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7)
  PKG_HASH:=3facbd55aa8c29727ae1ade020e879eb39cd8c58d87cb4055ce228349b15a2c9
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_neon-vfpv4)
  PKG_HASH:=cb7d2c068419b4f0ce301cd905fa20e28496c8ed96376b9104803623e580f570
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_vfpv4)
  PKG_HASH:=8675b1b6faef33386a074dcb37321ad85b465e596afcd3a9a8e56933b9490d82
else ifeq ($(ARCH_PACKAGES),arm_cortex-a8_vfpv3)
  PKG_HASH:=52183593d9b405bf1dd007f103cb3e1e63d48fe1bb614d369204febc1d6cb259
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9)
  PKG_HASH:=3b2c6c1641ae99fcbfb53be82e024a94d767fe65f9f45ab549415c77ba191215
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_neon)
  PKG_HASH:=26ce98095902be58375a826b8603057b7eac6cf0e65d0cd53ff1119e7cb0570b
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_vfpv3-d16)
  PKG_HASH:=336f183d639fb05d48107598717588752c98db764c5dbefb18fc643c9c33a7ba
else ifeq ($(ARCH_PACKAGES),arm_mpcore)
  PKG_HASH:=7cb546a80eb7466e14ebd10f7172c25088a7242bd6b0c428e860f9d228f3a0ce
else ifeq ($(ARCH_PACKAGES),arm_xscale)
  PKG_HASH:=e31d7b7b8e0e063e33d8208c3ca1f7c0588030dcabe1df28e4959a4968707520
else ifeq ($(ARCH_PACKAGES),mipsel_24kc)
  PKG_HASH:=db1eee25bc417f5785a9a537aee1503f4f6bffb6effcbbe202ed73576ee20ed5
else ifeq ($(ARCH_PACKAGES),mipsel_mips32)
  PKG_HASH:=4deae82fed26d9455cbeff2f12093e6037f3f993fbbc449446bfda16e49c869b
else ifeq ($(ARCH_PACKAGES),riscv64)
  PKG_HASH:=973930d0abda895d1414a611f9bea70a1a35c1b9965fc9062f2bb0900cbcd617
else ifeq ($(ARCH_PACKAGES),x86)
  PKG_HASH:=574dfa733c671d7d3125f53cf01f3f52d758a49cafc8df0e216e5ad5b501a149
else ifeq ($(ARCH_PACKAGES),x86_64)
  PKG_HASH:=8fabab9496f947f90d2a4b72379069d53c132cdb14a092898c628ed0e7879d4a
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
