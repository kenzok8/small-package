# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=naiveproxy
PKG_VERSION:=130.0.6723.40-4
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
  PKG_HASH:=caf705c6ef3ee9a3d0bf5500b7090f31b0a6bc277ac0cd9026374dd6214a8fea
else ifeq ($(ARCH_PACKAGES),aarch64_cortex-a72)
  PKG_HASH:=742b746adf949f5b2b283cb1590d1f5cad965c136165428bccfd3ab4fa502f6c
else ifeq ($(ARCH_PACKAGES),aarch64_generic)
  PKG_HASH:=ac82e49990f968a63fad0167a3da56dbea6fe0a27dccc722c4c53be7917422cc
else ifeq ($(ARCH_PACKAGES),arm_arm1176jzf-s_vfp)
  PKG_HASH:=02cf41769a7be2544460f1ac7ccd19b330efd3bc12fb39b97bdcb03f7c13f267
else ifeq ($(ARCH_PACKAGES),arm_arm926ej-s)
  PKG_HASH:=cbc2f655736bc7fd53132bc7219894567b24369c9ed31a040152962cd7e53850
else ifeq ($(ARCH_PACKAGES),arm_cortex-a15_neon-vfpv4)
  PKG_HASH:=047552793e62294bc3465130a70f0491544f10e1307a3ded396ea9b771fcaf48
else ifeq ($(ARCH_PACKAGES),arm_cortex-a5_vfpv4)
  PKG_HASH:=87aa43d7d73980aff913cba2655be5e2f8a565e8f842c59987e17555f944adaf
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7)
  PKG_HASH:=ff478984a8d3253de99e3db51213a64adbe89433f5560774c7cac35632f4ac2a
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_neon-vfpv4)
  PKG_HASH:=cf81122cf6c8784facc611edf811b17eb2a4c44ac289868dcac3536e55d4f979
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_vfpv4)
  PKG_HASH:=83ae798080420fa21e2056033807aedc6fdf4806346630e008c82f448a133e1e
else ifeq ($(ARCH_PACKAGES),arm_cortex-a8_vfpv3)
  PKG_HASH:=66e78250179d918322d77219b1e8ca96ab6ab5ac7c043e6486e2da9765444cf8
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9)
  PKG_HASH:=d8c7f6b658e2539c1cba83d275947ade2eace8ecb71dcf9dd04f26b6700ac28a
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_neon)
  PKG_HASH:=a6fe68edc537e56f41bd1ea30d0f8e0f9a585b6e464be7ad4042a72cac8c680e
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_vfpv3-d16)
  PKG_HASH:=4462b1b2d95c516fdc4bd24535db32e4655a551b8b86a3036956d72d42ff7a4a
else ifeq ($(ARCH_PACKAGES),arm_mpcore)
  PKG_HASH:=c106d135b23139c6a7b1b43008d30ced6687b4eb0746185c04baa0d1baa2d5f3
else ifeq ($(ARCH_PACKAGES),arm_xscale)
  PKG_HASH:=e2683fa31170ca028220dd8cc9fdf106ea6ead13f1e6884b12e64e8d0c7162b6
else ifeq ($(ARCH_PACKAGES),mipsel_24kc)
  PKG_HASH:=7130c03db4b1de3a7c84f57a3e1d678625d370492addfe04d54f9d8d2d098a8f
else ifeq ($(ARCH_PACKAGES),mipsel_mips32)
  PKG_HASH:=74ea31b453d01cf879ea9a5ca68cde154cb408bf8d01730ad3736f3d232a80ce
else ifeq ($(ARCH_PACKAGES),riscv64)
  PKG_HASH:=5579495d590eb357d8efb030320e5e280044660f28540a3d1d3b2acbe28bb64c
else ifeq ($(ARCH_PACKAGES),x86)
  PKG_HASH:=8b32c4a1d3f11442c5e758b9b32e05054b7ffd9dcf6c237bd925ebe7ba0eb782
else ifeq ($(ARCH_PACKAGES),x86_64)
  PKG_HASH:=38fbec54d27936fb9323110ffa629587100808027f85e7632deeb82a6236d886
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
