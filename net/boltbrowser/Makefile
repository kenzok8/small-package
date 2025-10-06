include $(TOPDIR)/rules.mk

PKG_NAME:=boltbrowser
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/br0xen/boltbrowser.git
PKG_SOURCE_DATE:=2023-05-31
PKG_SOURCE_VERSION:=fcc13603daaff080fb31f26c26cfa370b63edfa1
PKG_MIRROR_HASH:=62448b97592bc4b5f51252736e35b319b5170c4d8e42ebda1f0b43a1c96dc011

PKG_LICENSE:=GPL-3.0-or-later
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Tianling Shen <cnsztl@immortalwrt.org>

PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1
PKG_BUILD_FLAGS:=no-mips16

GO_PKG:=github.com/br0xen/boltbrowser

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk

define Package/boltbrowser
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=A CLI Browser for BoltDB Files
  URL:=https://github.com/br0xen/boltbrowser
  DEPENDS:=$(GO_ARCH_DEPENDS)
endef

$(eval $(call GoBinPackage,boltbrowser))
$(eval $(call BuildPackage,boltbrowser))
