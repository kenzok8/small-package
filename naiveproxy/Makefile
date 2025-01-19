# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=naiveproxy
PKG_VERSION:=132.0.6834.79-2
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
  PKG_HASH:=24548efa8a257320a169b9a9f4692043dc00ee7c35bd211ea04a2ec161bbf39d
else ifeq ($(ARCH_PACKAGES),aarch64_cortex-a72)
  PKG_HASH:=2849150414fd7ab21552cedc21bfa1c41a6ff1e1c3aa3cc2d44436aab74912e1
else ifeq ($(ARCH_PACKAGES),aarch64_generic)
  PKG_HASH:=71fbc160c5f8df9ae96d7f91b646e24f2eb142928df8186fe50a9d73cfac842e
else ifeq ($(ARCH_PACKAGES),arm_arm1176jzf-s_vfp)
  PKG_HASH:=7ce0ba453c09f9978e421575aca96b34d381ec1731f19d29d8e16e7968fb1888
else ifeq ($(ARCH_PACKAGES),arm_arm926ej-s)
  PKG_HASH:=000d92d9865f406dfd9bf7848c455312a1ce42a778c970f484bdf93c3a805973
else ifeq ($(ARCH_PACKAGES),arm_cortex-a15_neon-vfpv4)
  PKG_HASH:=94f22ed0e270d47b035ec6380ce6b26db93ff01382641c222f2db11929cc0856
else ifeq ($(ARCH_PACKAGES),arm_cortex-a5_vfpv4)
  PKG_HASH:=a4cfc13e78000f3de8561f9f299e60536435b8e8b9208fc2ad34318662d78b28
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7)
  PKG_HASH:=e27d13fc44deecd5083d0e5cdf9f0df83a642df714f4a13a69b706bb5198a61e
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_neon-vfpv4)
  PKG_HASH:=15315b9671ca61fb848b4e8d6f8162a1ce9fc9fe4fad3702678256fa90414641
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_vfpv4)
  PKG_HASH:=6ad229a26fdaac664fa0bc5f8f4417e034fbf7ea8d6719eaf26882b758f8864e
else ifeq ($(ARCH_PACKAGES),arm_cortex-a8_vfpv3)
  PKG_HASH:=871a8bc18bfcd5d9e2dcd965887be2f5617c9baec5bd0a6d17a5569782a69b8b
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9)
  PKG_HASH:=137eb801293e8a3336626dc58434ee135751960332d8237d6c54aa6944eb17d4
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_neon)
  PKG_HASH:=deace84168fdce2656c0b6d9fa094fdd8dbdd4e8f95c422043f5dee7cbdb5d26
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_vfpv3-d16)
  PKG_HASH:=51e4ee3521b575fc2c12a1baa276e0802d3fc10a32a62f190c2c9b56c008e40d
else ifeq ($(ARCH_PACKAGES),arm_mpcore)
  PKG_HASH:=008d2231c867614dc3e40c966261d9dc5c9931b3c68beb33549ad3d4f7bed2f1
else ifeq ($(ARCH_PACKAGES),arm_xscale)
  PKG_HASH:=d8160e3b0963d124eb91762c6df9d96207510dc1a5f28f32f3ad6f6133f49d75
else ifeq ($(ARCH_PACKAGES),mipsel_24kc)
  PKG_HASH:=f9c0a4049388058aaa881aa13385470497beaeeca6473baf6539905a75d098bf
else ifeq ($(ARCH_PACKAGES),mipsel_mips32)
  PKG_HASH:=fd2520202c1cbe82498c90594a71cd1ed6aa4d8a6d470cf84871fd1d8f646380
else ifeq ($(ARCH_PACKAGES),riscv64)
  PKG_HASH:=557f8054e7643d6cdbbd1f70922ddf131f60ad03fb2cadf994ac15c9303d84ed
else ifeq ($(ARCH_PACKAGES),x86)
  PKG_HASH:=eab01156720906345230f6fb9cde7580b88e66799a4bdcef58636addbcab9a6c
else ifeq ($(ARCH_PACKAGES),x86_64)
  PKG_HASH:=95fd43646b86512ea46d87ccd0b5adda50aefe5c53dbcfd4b47930a146bec8b9
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
