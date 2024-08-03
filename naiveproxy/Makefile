# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=naiveproxy
PKG_VERSION:=127.0.6533.64-2
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
  PKG_HASH:=856451a837422d3cce314859ed929912071321de04cbe044bd7f82de972bb670
else ifeq ($(ARCH_PACKAGES),aarch64_cortex-a72)
  PKG_HASH:=dcd1a9a981a082805cdba714ffafce1ad5d6146951a92761bfc8c5157b2152cd
else ifeq ($(ARCH_PACKAGES),aarch64_generic)
  PKG_HASH:=a228558aa327c450e8631a8f855669f18801ea17f5efb1c32eced495e5b84597
else ifeq ($(ARCH_PACKAGES),arm_arm1176jzf-s_vfp)
  PKG_HASH:=7f90787828eb2bb2a957e70da4f9e500b4abd1bf7a9ff6ef2636a004e5314a2f
else ifeq ($(ARCH_PACKAGES),arm_arm926ej-s)
  PKG_HASH:=80fb0562a279659ff0811cee441e319587505bbc06ad4b271f4d1fefa1c7f672
else ifeq ($(ARCH_PACKAGES),arm_cortex-a15_neon-vfpv4)
  PKG_HASH:=0d378b74c59025973c2f9e8577bc514be6601fc191c3cbbbabad427793fc4df9
else ifeq ($(ARCH_PACKAGES),arm_cortex-a5_vfpv4)
  PKG_HASH:=72433296d6417ee0edce2246e4c107f71253b1b2dd6cd6cf89da8e462a381a05
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7)
  PKG_HASH:=553e36d2eb3afe2618b4af9e8d5f19aae1fe3bff867b10d1406b4a204f647fe9
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_neon-vfpv4)
  PKG_HASH:=5edce6d98dc6d631708db4cbe64a811b423a4cd3c9d3a017cd0f9ee128dcff12
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_vfpv4)
  PKG_HASH:=0bb1dc4c539bd4268dcb640a413413772a866724d7f1aa73cac3de82314dcc5b
else ifeq ($(ARCH_PACKAGES),arm_cortex-a8_vfpv3)
  PKG_HASH:=7acec9e59793201243f6c76ee0ab1def62ca8ee539207f55830cd8a1585ed294
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9)
  PKG_HASH:=aba4212b3e2af6e248ebbda90b43d55ea9a9448c3f578b6c9545027a1c54c111
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_neon)
  PKG_HASH:=70845dcd459834822a3bc8e68f2d19ee230f6768d20c79ffcc443a19b6334e6b
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_vfpv3-d16)
  PKG_HASH:=e8d5501614d880c490cb6c0ad6d831c248de2668e07b7c98ee79c2f2f719fe19
else ifeq ($(ARCH_PACKAGES),arm_mpcore)
  PKG_HASH:=a132692b8ac678ff6d40cb22767da80ef83b7f6c4f81242d8f033721d33ecc83
else ifeq ($(ARCH_PACKAGES),arm_xscale)
  PKG_HASH:=e0f10115b225bdffbdcbc550bc2baeeb1ea9e174926430ef848c5b767cefdc78
else ifeq ($(ARCH_PACKAGES),mipsel_24kc)
  PKG_HASH:=ccd2421d48ddcfc29633fe2059e0bb62a8dc7550de4d70892c50b898bab4dcc4
else ifeq ($(ARCH_PACKAGES),mipsel_mips32)
  PKG_HASH:=606b82c1bdaa84ec80be074b0551f12b79f36cf13be90e481da947397096632b
else ifeq ($(ARCH_PACKAGES),riscv64)
  PKG_HASH:=f2784f78ef577e41cb71cdb1e0cd59d05b5215e9ff99384835b51fa2017ea029
else ifeq ($(ARCH_PACKAGES),x86)
  PKG_HASH:=afc71f4e0a45e5103e54ecc18a8c43e3d2b016c9a1d3113b3e483573e556171b
else ifeq ($(ARCH_PACKAGES),x86_64)
  PKG_HASH:=315a2321655f2d3dd8a54f5538e52b3d21d15df0d09e66c2b1f6afb83f427eb8
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
