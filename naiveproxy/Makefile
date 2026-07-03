# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=naiveproxy
PKG_REAL_VERSION:=150.0.7871.63-1
PKG_VERSION:=$(subst -,.,$(PKG_REAL_VERSION))
PKG_RELEASE:=1

ARCH_PREBUILT:=$(ARCH_PACKAGES)
ifeq ($(ARCH_PREBUILT),aarch64_cortex-a76)
  ARCH_PREBUILT:=aarch64_generic
else ifeq ($(ARCH_PREBUILT),i386_pentium-mmx)
  ARCH_PREBUILT:=x86
else ifeq ($(ARCH_PREBUILT),i386_pentium4)
  ARCH_PREBUILT:=x86
else ifeq ($(ARCH_PREBUILT),riscv64_riscv64)
  ARCH_PREBUILT:=riscv64
endif

ifeq ($(ARCH_PREBUILT),aarch64_cortex-a53)
  PKG_HASH:=ccaa39f0cf6b359f7f915642b54829f06cf45e7b093c27ab93629e7353dcb479
else ifeq ($(ARCH_PREBUILT),aarch64_cortex-a72)
  PKG_HASH:=0709d2624b32df1d15e70d53d9dbd60b785931f28db929e498b4517369e01d1c
else ifeq ($(ARCH_PREBUILT),aarch64_generic)
  PKG_HASH:=439705d5012523f3095aab8acf62420913f0f630305b2e7d55b295b3adb9cc50
else ifeq ($(ARCH_PREBUILT),arm_arm1176jzf-s_vfp)
  PKG_HASH:=8897dd52fc42d655c322d38a3b01ec5fdb63b522be81da1ea75b965b4d869318
else ifeq ($(ARCH_PREBUILT),arm_arm926ej-s)
  PKG_HASH:=64301d029a7ace6e78e81a593336af92a90ce78501502bcaee26570912444fb3
else ifeq ($(ARCH_PREBUILT),arm_cortex-a15_neon-vfpv4)
  PKG_HASH:=0aea21249089047ac2aad5fe889e76c25e0c4c498e113660e807d9114703926e
else ifeq ($(ARCH_PREBUILT),arm_cortex-a5_vfpv4)
  PKG_HASH:=f64ca5222ec7298643c412e08ac2316bf1250581c11f1ffa0258b13ad37d6210
else ifeq ($(ARCH_PREBUILT),arm_cortex-a7)
  PKG_HASH:=a09f55467cf7c1d90dc4d30019f85e2047f632e94ec519724fc837b72fb56940
else ifeq ($(ARCH_PREBUILT),arm_cortex-a7_neon-vfpv4)
  PKG_HASH:=3f559c5e0958798e020ce62a5810e71ee84566598c3f0ef2ab8eb0b85186c85e
else ifeq ($(ARCH_PREBUILT),arm_cortex-a7_vfpv4)
  PKG_HASH:=2268610cfada67e03dbac36c3294bdb528ecfcc7de6d820fc4e837757310d5dc
else ifeq ($(ARCH_PREBUILT),arm_cortex-a8_vfpv3)
  PKG_HASH:=2d7ed1c46a2dbf3c50f8f4af29a0ef6bea5b7a90f3ac58667f2f34592514f8cc
else ifeq ($(ARCH_PREBUILT),arm_cortex-a9)
  PKG_HASH:=b4cf57ae285409129ba5cf000840044f5969c03b6239d68c84b2487de4e91a00
else ifeq ($(ARCH_PREBUILT),arm_cortex-a9_neon)
  PKG_HASH:=06d42885b6fca15e1884bda38bfabcce93b369735de3c6fe472bfa7346bde55d
else ifeq ($(ARCH_PREBUILT),arm_cortex-a9_vfpv3-d16)
  PKG_HASH:=6cb58404e5404f46f0afd3bc07362558ea75c2a0391c7603b161a4c5b81b55c3
else ifeq ($(ARCH_PREBUILT),arm_mpcore)
  PKG_HASH:=1cdb51b2cea9c72fd7f0b5209dddb242cb22008afb3ecaacf06e0c0f02f11996
else ifeq ($(ARCH_PREBUILT),arm_xscale)
  PKG_HASH:=7a80092ff4497fd0aabb571f942c8c939879b18b8d983d567b66b4c8e80ef31d
else ifeq ($(ARCH_PREBUILT),mipsel_24kc)
  PKG_HASH:=55c9aea6ad32034151ad66e3db66740e834dad7a850a746cb085137f40284f75
else ifeq ($(ARCH_PREBUILT),mipsel_mips32)
  PKG_HASH:=b0fe1e6e4386f4298314640355a777ba85e2466a7ea7006d29178fc185496f08
else ifeq ($(ARCH_PREBUILT),riscv64)
  PKG_HASH:=824056ca2d7192ae071f9e017b69a3281ebf7f5ee18657192a0ef1a6563263e8
else ifeq ($(ARCH_PREBUILT),x86)
  PKG_HASH:=0c12e6fee7b6b8f94b0feb0aca5f5ba8930ad61e4bda43792a84791247c53d36
else ifeq ($(ARCH_PREBUILT),x86_64)
  PKG_HASH:=f817de82e88aba3cfe0a773816e2717c94dac050fb931055b3d6d5c1e75992bb
else
  PKG_HASH:=dummy
endif

PKG_SOURCE:=naiveproxy-v$(PKG_REAL_VERSION)-openwrt-$(ARCH_PREBUILT).tar.xz
PKG_SOURCE_URL:=https://github.com/klzgrad/naiveproxy/releases/download/v$(PKG_REAL_VERSION)/
PKG_BUILD_DIR:=$(BUILD_DIR)/naiveproxy-v$(PKG_REAL_VERSION)-openwrt-$(ARCH_PACKAGES)

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
