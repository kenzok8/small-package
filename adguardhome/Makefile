#
# 这是免费软件，根据 GNU 通用公共许可证 v2 获得许可。
# 请参阅 /LICENSE 了解更多信息。
#

包括 $(TOPDIR)/rules.mk

PKG_NAME:=adguardhome
PKG_VERSION:=0.107.38
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_VERSION:=v$(PKG_VERSION)
PKG_SOURCE_URL:=https://github.com/AdguardTeam/AdGuardHome
PKG_MIRROR_HASH:=6c00a63ad5c76264fa9cf8a6aa1e82f94f4bad7c36733b1922cf5b2829e3ed14

PKG_LICENSE:=仅限 GPL-3.0
PKG_LICENSE_FILES:=LICENSE.txt
PKG_MAINTAINER:=Dobroslaw Kijowski <dobo90@gmail.com>

PKG_BUILD_DEPENDS:=golang/主机节点/主机节点-yarn/主机节点
PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0
PKG_BUILD_FLAGS:=no-mips16

GO_PKG:=github.com/AdguardTeam/AdGuardHome
GO_PKG_BUILD_PKG:=github.com/AdguardTeam/AdGuardHome

AGH_BUILD_TIME:=$(shell 日期 -d @$(SOURCE_DATE_EPOCH) +%FT%TZ%z)
AGH_VERSION_PKG:=github.com/AdguardTeam/AdGuardHome/internal/version
GO_PKG_LDFLAGS_X:=$(AGH_VERSION_PKG).channel=发布\
	$(AGH_VERSION_PKG).version=$(PKG_SOURCE_VERSION) \
	$(AGH_VERSION_PKG).buildtime=$(AGH_BUILD_TIME) \
	$(AGH_VERSION_PKG).goarm=$(GO_ARM) \
	$(AGH_VERSION_PKG).gomips=$(GO_MIPS)

包含$(INCLUDE_DIR)/package.mk
包括 $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk

定义包/adguardhome
	部分：=净
	类别：=网络
	TITLE:= 网络范围内的广告和跟踪器阻止 DNS 服务器
	网址：=https://github.com/AdguardTeam/AdGuardHome
	依赖:=$(GO_ARCH_DEPENDS) +ca-bundle
恩德夫

定义包/adguardhome/conffiles
/etc/adguardhome.yaml
/etc/config/adguardhome
恩德夫

定义包/adguardhome/描述
免费开源、功能强大的全网广告和跟踪器，可阻止DNS服务器。
恩德夫

定义 构建/编译
	(\
		推 $(PKG_BUILD_DIR) ; \
		使 js-deps js-build ；\
		弹出；\
		$(调用 GoPackage/构建/编译) ; \
	）
恩德夫

$(eval $(调用GoBinPackage,adguardhome))
$(eval $(调用 BuildPackage,adguardhome))
