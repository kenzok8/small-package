# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=naiveproxy
PKG_VERSION:=123.0.6312.40-1
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
  PKG_HASH:=222c98c471ca1212cd12f41e191e815d6b2df6175025bfa119142f9d7a8c8758
else ifeq ($(ARCH_PACKAGES),aarch64_cortex-a72)
  PKG_HASH:=38ba89a7fbd954bf47634f96c2942c398cb56d595a4621d1f441fe031914685e
else ifeq ($(ARCH_PACKAGES),aarch64_generic)
  PKG_HASH:=f4f57a08741a247524e8738400f27f1b0e2a0f22c6d2b84f1c838457dd594205
else ifeq ($(ARCH_PACKAGES),arm_arm1176jzf-s_vfp)
  PKG_HASH:=a9ae3d38d1c2d05c3413860fe0faebee2310410d42c015bb12c55eab119a0a23
else ifeq ($(ARCH_PACKAGES),arm_arm926ej-s)
  PKG_HASH:=a76b19b4c977ce6595eaeb4c373fac680e9f3d66a084031752ab26808a369131
else ifeq ($(ARCH_PACKAGES),arm_cortex-a15_neon-vfpv4)
  PKG_HASH:=5166ec17e83a8d9d009c1ba07ac0d9b8669a34deb7c8fc7822d40610be0300f6
else ifeq ($(ARCH_PACKAGES),arm_cortex-a5_vfpv4)
  PKG_HASH:=f7e3540a3e5beeef4eb9e9ce8ad26f538e648f2dda657babb24ae05b1cce9dee
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7)
  PKG_HASH:=7c34045a89465650a3127e99e6ccaaea126ea1c3c4680600cc9808c5a0dae56b
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_neon-vfpv4)
  PKG_HASH:=639301cd6a5cbe98561d04323011d8fa41a9cfe5f8611ac0394b9856d8756865
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_vfpv4)
  PKG_HASH:=8401af8d1bfa67d341cd0e6d4b26fd1c2b906933c75e76ca338dbcc6f2f6d18e
else ifeq ($(ARCH_PACKAGES),arm_cortex-a8_vfpv3)
  PKG_HASH:=77d84fa6595f64d627849bd10285cebddc5785902242c9f76880f134c454b7ff
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9)
  PKG_HASH:=e06be005325bf520fc7eaa4a09c0bdcc4d3adc279d91557861e7712fa721d548
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_neon)
  PKG_HASH:=3a2e46e52685beeb5cc9c1f8a6ab7729e9334082015a7c7ac2b97276c62b139a
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_vfpv3-d16)
  PKG_HASH:=5365c51001d8ac4af77afdfb99081083b8baef1998270d37c8f72ccfe90a4d6c
else ifeq ($(ARCH_PACKAGES),arm_mpcore)
  PKG_HASH:=45d085c0d8a71394484a002cf27a578750d48a2079c6f7370d161ef29feb54bf
else ifeq ($(ARCH_PACKAGES),arm_xscale)
  PKG_HASH:=80320bd47ee05d77b327b570e469cec601d18d1d0a1223f04528497296267049
else ifeq ($(ARCH_PACKAGES),mipsel_24kc)
  PKG_HASH:=bff1b5f1e55a79e440964c1c2c0f0251fa52265025183f0428f5ddd4af6eefef
else ifeq ($(ARCH_PACKAGES),mipsel_mips32)
  PKG_HASH:=f07a072843ce5c31aec640a3271a765bd26612c0bdefc167c54a639b657619ad
else ifeq ($(ARCH_PACKAGES),riscv64)
  PKG_HASH:=1dc9570f0f95976f3ea0a4d99c0a0340f98f7cb9488eefd86b87bb346f6d6d39
else ifeq ($(ARCH_PACKAGES),x86)
  PKG_HASH:=ddeba2d8b635d4c0f6583b986ed04700262f1c24817ce76a0aca9a9bacb0ade7
else ifeq ($(ARCH_PACKAGES),x86_64)
  PKG_HASH:=9438d78159f236bccc1f3491222e58af08c6864600ef5a989542f143eb3c0972
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
