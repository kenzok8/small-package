# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=naiveproxy
PKG_VERSION:=128.0.6613.40-1
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
  PKG_HASH:=feaefc5e55d50c4ca9b76ea322dd55c68759708f10f026ea446d30ba370c39fd
else ifeq ($(ARCH_PACKAGES),aarch64_cortex-a72)
  PKG_HASH:=aa7f5b0297d1f66210752457eee5bdb564872fe532b5c62309309f8d77abe3b8
else ifeq ($(ARCH_PACKAGES),aarch64_generic)
  PKG_HASH:=6f5a57edec4439725df011909319002748f2b2cfbf5a0386c42a97eb2cdf864f
else ifeq ($(ARCH_PACKAGES),arm_arm1176jzf-s_vfp)
  PKG_HASH:=1611f9d1259089364ccc541a080b223d3de5d198a85dabee65bd03762b535bcf
else ifeq ($(ARCH_PACKAGES),arm_arm926ej-s)
  PKG_HASH:=6b4d03bd232a13a0720dfba077bd1847617a1fb699bcf20ffee182c49643ccfb
else ifeq ($(ARCH_PACKAGES),arm_cortex-a15_neon-vfpv4)
  PKG_HASH:=036af44c9bd818a369cd0b391995d802bb01b46fb868fb7b487b8aceb57355fc
else ifeq ($(ARCH_PACKAGES),arm_cortex-a5_vfpv4)
  PKG_HASH:=bdae0724f844da0224a94318193238f59e9766c86b05d6dd7bbdcd3b14773fa5
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7)
  PKG_HASH:=c6ca6644df5d57b241a212bea3d11427bb369a67d58d3352e7aa488ef56f34e2
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_neon-vfpv4)
  PKG_HASH:=ded055c58d29849532975d203e03f0347c41b88047cd0651638a0555acbaa1a3
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_vfpv4)
  PKG_HASH:=694d438987957c1b0794ad25f3d5e1411f8ab2edf4d6f7510e13f238fd36f64f
else ifeq ($(ARCH_PACKAGES),arm_cortex-a8_vfpv3)
  PKG_HASH:=b812efc3eda1841acee9cd83c2ae049a8b1981437f4eed33f6947aca85aa07b8
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9)
  PKG_HASH:=cd40f3b7b5c20be420e2b5240ffe1ef84a058fe06aebcd674ce421e4e23db549
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_neon)
  PKG_HASH:=e5df785a494642d866c27e35daa455b460302c2d84be66d86dd55d285bfad2c0
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_vfpv3-d16)
  PKG_HASH:=15337f6942e3122b83a3764e9c23ee03f1ebd54cfc5205ba6677c0cf3af97ded
else ifeq ($(ARCH_PACKAGES),arm_mpcore)
  PKG_HASH:=2c2be2c624b0ba6462f71e14e592ec3abc77b4387a3c5786587372ff735d4fef
else ifeq ($(ARCH_PACKAGES),arm_xscale)
  PKG_HASH:=b03855162f516600704898545269a99bf52b4abeb2da7d12d412186f8830704f
else ifeq ($(ARCH_PACKAGES),mipsel_24kc)
  PKG_HASH:=2ac11b97037a5b5628bf8b858ee59db53f79ab15fc589533a0b1a61f68876fcf
else ifeq ($(ARCH_PACKAGES),mipsel_mips32)
  PKG_HASH:=98963a397406082cd2b236f701b7e696b0814677485eccbf60332d47ed54cc28
else ifeq ($(ARCH_PACKAGES),riscv64)
  PKG_HASH:=ca347b75ba47a80105fb915f1b85b4f1654a05a6b437244715ee6bd4310bf771
else ifeq ($(ARCH_PACKAGES),x86)
  PKG_HASH:=6594a79adae775045168ca4609a9bde9204f46af76b56a20f4bf524c65824ac4
else ifeq ($(ARCH_PACKAGES),x86_64)
  PKG_HASH:=3281ee8957956ec5a5028bd34f1f8053609daf7043ce846462595a1f0d89147e
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
