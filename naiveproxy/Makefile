# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=naiveproxy
PKG_VERSION:=131.0.6778.86-1
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
  PKG_HASH:=5cdb9ca045995bfb41d76b5321090255fb8ea7ec22aedd8a72f4aa1cbca1c456
else ifeq ($(ARCH_PACKAGES),aarch64_cortex-a72)
  PKG_HASH:=c4151ced17629b9267b07cc13bb5ca3cc0931a4205630a407e88611bb605aa85
else ifeq ($(ARCH_PACKAGES),aarch64_generic)
  PKG_HASH:=c2587d13ef960d4efd0e2b5debb1b7a952b368838f7baac047183925fd7c896c
else ifeq ($(ARCH_PACKAGES),arm_arm1176jzf-s_vfp)
  PKG_HASH:=dc31a9ba7e6c7b6c12fc7e46d75a99768d8cb5158c35aa32bd00a89a78799185
else ifeq ($(ARCH_PACKAGES),arm_arm926ej-s)
  PKG_HASH:=979b513f5f246f856379016abf43c630ae1085f05cdb9d20ef29635c554a35f0
else ifeq ($(ARCH_PACKAGES),arm_cortex-a15_neon-vfpv4)
  PKG_HASH:=122f72dd6a21b122db36b0cf8248124ffaad51825e07569aaa71394cc38fd540
else ifeq ($(ARCH_PACKAGES),arm_cortex-a5_vfpv4)
  PKG_HASH:=2b9306942a692f606e4d169a5acff4e8b7e6c7fc4df445d0372eecfdbba4b0c7
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7)
  PKG_HASH:=308e22352b0bf042341cd96b0c3b54a6fdc7aa6d62b98fa1d298b081b62cf699
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_neon-vfpv4)
  PKG_HASH:=d925050e6ab276d3cff72c5e3ff4d348a9f49056a9cc60d9608ef272880cffc1
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_vfpv4)
  PKG_HASH:=a96c5da149008230a96474b1c13db25bff9439df6d29420d36a7d5ba2462ea24
else ifeq ($(ARCH_PACKAGES),arm_cortex-a8_vfpv3)
  PKG_HASH:=92d9b6c5b5a020b14897b4645564843449f1bbf5d73e65cf2edfee8208ad3034
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9)
  PKG_HASH:=06a9f0c0aeddda61137568e56cf42dd1824e3603954a4a6447232f933182cb0e
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_neon)
  PKG_HASH:=9d869d3e1d3fd454b7aa6c8f099c66fa8dd4a29998ef5f84abadb6a2a4d35769
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_vfpv3-d16)
  PKG_HASH:=9a5167d490c00dae1d7799cbb0a93dac4984cc52426e54d5ed762780f53967cd
else ifeq ($(ARCH_PACKAGES),arm_mpcore)
  PKG_HASH:=0b92a0262eba5b494238e960e8feab9b72ae0ea1e6448df188d76738355b5093
else ifeq ($(ARCH_PACKAGES),arm_xscale)
  PKG_HASH:=78cf3a4c1b64caf21fb40973fc0777359440e5e247500529d89b403a06dd9971
else ifeq ($(ARCH_PACKAGES),mipsel_24kc)
  PKG_HASH:=6085a39eb46ace69fb9eacb6f1d9b00c167dee4e85b205ed277a42223a6fc07f
else ifeq ($(ARCH_PACKAGES),mipsel_mips32)
  PKG_HASH:=77514fb5b6340fd2b6464f8a12ca0acf27805ac2de8db1b5235d95d3f754bf20
else ifeq ($(ARCH_PACKAGES),riscv64)
  PKG_HASH:=4ce2d5d65a4296c356b285346e8b423202c4a527f68d69da993287fe60c8e4fd
else ifeq ($(ARCH_PACKAGES),x86)
  PKG_HASH:=b981dd9e5eed9bea14edd5f21f3cf03fd6dd0ae81f43471c9cc7ec1682c22662
else ifeq ($(ARCH_PACKAGES),x86_64)
  PKG_HASH:=a628a7cf69110facbeb8b657785683a12db45f982f14534d67401197a867b28f
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
