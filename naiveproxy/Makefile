# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=naiveproxy
PKG_VERSION:=136.0.7103.44-2
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
  PKG_HASH:=c8bfc343b40f8412a0dc61e5e972c7aa74d16dbe106c09cc2aa6d74ab691d88f
else ifeq ($(ARCH_PACKAGES),aarch64_cortex-a72)
  PKG_HASH:=0f4976f74289506eb97197d9f07d34e9772c18d3296d940b1ff92180020ec8ee
else ifeq ($(ARCH_PACKAGES),aarch64_generic)
  PKG_HASH:=a1205581557629a936d03b93dafb0546356b0849943bf9262c6c89be50314cf8
else ifeq ($(ARCH_PACKAGES),arm_arm1176jzf-s_vfp)
  PKG_HASH:=65466cf93a5c46c3ea3ec8c3bdfe275cd0cff61eaca7d27c80f4136a4e7f7832
else ifeq ($(ARCH_PACKAGES),arm_arm926ej-s)
  PKG_HASH:=1d8822ff5f77dde52dfe8f108802e232ee74fc85931c1b536f15ffcce4f99c1a
else ifeq ($(ARCH_PACKAGES),arm_cortex-a15_neon-vfpv4)
  PKG_HASH:=cec6aff2351c6db6a7e6ef512470c9f2b883fc368a87f071594c19425109eabe
else ifeq ($(ARCH_PACKAGES),arm_cortex-a5_vfpv4)
  PKG_HASH:=dae6a7439f8049ecdcc658478f0ca473cddf00d4a377df591d6967fb8698da0a
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7)
  PKG_HASH:=817b84e650372ea33b7fd2ed6e484e13a6d0aaf559d5f96caafdc4ab1116b7e7
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_neon-vfpv4)
  PKG_HASH:=73aee449f61c6d18152e3bc5c1dd78c5ca434d89e011863f7e85f2ce7b952224
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_vfpv4)
  PKG_HASH:=7833cf68fcfeffaff848360eefa1db21b731dc13609cecca5d037e1e16d14c0f
else ifeq ($(ARCH_PACKAGES),arm_cortex-a8_vfpv3)
  PKG_HASH:=629941b6fb2823d35a0cc04cd47bda5c7c8796bc168374483a933bd60fa24d1b
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9)
  PKG_HASH:=a85f6facbdaa9ef470ebd235b5c7d026e63e71102a635354d725a1933a9a238c
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_neon)
  PKG_HASH:=a8d01014860037a3f8601f29998f2bbf1a442fbfcb168d11fcc76571697dcf76
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_vfpv3-d16)
  PKG_HASH:=d442c8e6643614c4274efa9c27808c54e16e1eb5e384dbc443c89765f95162b8
else ifeq ($(ARCH_PACKAGES),arm_mpcore)
  PKG_HASH:=a7b2475877ea0c9dee713a56c7483913f47c3666b74f5f7a13e45b846f899a06
else ifeq ($(ARCH_PACKAGES),arm_xscale)
  PKG_HASH:=f95f34aef471ad8f259312d8e87a6df316d19c40dcc486b7b7004959bd1704f2
else ifeq ($(ARCH_PACKAGES),mipsel_24kc)
  PKG_HASH:=da36e99151e2d67e4eee8d6e33e5e65b158cbe43306edece7e30c638c4ac6baa
else ifeq ($(ARCH_PACKAGES),mipsel_mips32)
  PKG_HASH:=4e5b5fa559cd153ba60fa66ec5aa3271bfbb7985d23db7f4200b1a4b90977564
else ifeq ($(ARCH_PACKAGES),riscv64)
  PKG_HASH:=c865813ae10caa53ac5b6c0960b8e6b40de46af72f96c9b1ed992651860c3a4d
else ifeq ($(ARCH_PACKAGES),x86)
  PKG_HASH:=82d4f3d7b58c7a705610948d81cd7c4b3e67090500b00ea148b8e42b9aaf7f4e
else ifeq ($(ARCH_PACKAGES),x86_64)
  PKG_HASH:=843ab9f486c807e3c95cbe41d5d4be08b8098740d6f3082309df2a9384844269
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
