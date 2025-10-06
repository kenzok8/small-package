#
# Copyright (C) 2022 Ycarus (Yannick Chabanois) <ycarus@zugaina.org> for OpenMPTCProuter
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=grpcurl
PKG_VERSION:=1.8.6
PKG_RELEASE:=1

PKG_SOURCE:=v$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/fullstorydev/grpcurl/archive/refs/tags/
PKG_HASH:=18b457f644baabeef0de350596dd8d23563586ee94a3ed3cb290063e097ab934

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Yannick Chabanois <ycarus@zugaina.org>

PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

GO_PKG:=github.com/fullstorydev/grpcurl
GO_PKG_BUILD_PKG:=github.com/fullstorydev/grpcurl/cmd/grpcurl
GO_PKG_LDFLAGS_X:= \
    $(GO_PKG)/constant.Version=$(PKG_VERSION) \
    $(GO_PKG)/constant.Commit=v$(PKG_VERSION)
GO_PKG_LDFLAGS:=-s -w
GO_PKG_TAGS:=master

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk

define Package/grpcurl
  TITLE:=grpcurl is a command-line tool that lets you interact with gRPC servers
  URL:=https://github.com/fullstorydev/grpcurl
  SECTION:=net
  CATEGORY:=Network
  DEPENDS:=$(GO_ARCH_DEPENDS) +protobuf
endef

define Package/grpcurl/description
  grpcurl is a command-line tool that lets you interact with gRPC servers. It's basically curl for gRPC servers.

  The main purpose for this tool is to invoke RPC methods on a gRPC server from the command-line. gRPC servers use a binary encoding on the wire (protocol buffers, or "protobufs" for short). So they are basically impossible to interact with using regular curl (and older versions of curl that do not support HTTP/2 are of course non-starters). This program accepts messages using JSON encoding, which is much more friendly for both humans and scripts.
endef

define Package/v2ray-core/install
	$(call GoPackage/Package/Install/Bin,$(PKG_INSTALL_DIR))

	$(INSTALL_DIR) $(1)/usr/bin

	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/grpcurl $(1)/usr/bin
endef

$(eval $(call GoBinPackage,grpcurl))
$(eval $(call BuildPackage,grpcurl))
