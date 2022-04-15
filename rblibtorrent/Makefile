include $(TOPDIR)/rules.mk

PKG_NAME:=rblibtorrent
PKG_VERSION:=1.2.15
PKG_RELEASE=2

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/arvidn/libtorrent.git
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=1b25eb5584db5f335167e6f8beda1ae280f28445
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_MIRROR_HASH:=d0cb50a9dd6cc740dfa8f7a93be2c614a40165246c0454ae6f147cda7aa3f994

PKG_LICENSE:=BSD
PKG_LICENSE_FILES:=COPYING

PKG_USE_MIPS16:=0
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/rblibtorrent
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=Rasterbar BitTorrent library
  URL:=https://www.libtorrent.org/
  DEPENDS:=+libgcc +libstdcpp +libopenssl +boost +boost-system +boost-chrono +boost-random
  MAINTAINER:=Arvid Norberg <arvid@libtorrent.org>
endef

define Package/rblibtorrent/description
Rasterbar libtorrent is a C++ library that aims to be a good alternative to
all the other bittorrent implementations around. It is a library and not a
full featured client, although it comes with a working example client.
endef

TARGET_CFLAGS += $(if $(CONFIG_SOFT_FLOAT),-DBOOST_NO_FENV_H) -fPIC -ffunction-sections -fdata-sections -flto
EXTRA_CXXFLAGS += $(if $(CONFIG_GCC_VERSION_4_8),-std=gnu++11,-std=gnu++17) 
TARGET_LDFLAGS += -lstdc++ -Wl,--gc-sections,--as-needed -flto

CMAKE_OPTIONS += \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_CXX_STANDARD=17 \
	-DBUILD_SHARED_LIBS=ON \
	-Ddeprecated-functions=ON  \
	-Dencryption=ON \
	-Diconv=ON \
	-Dstatic_runtime=ON \
	-Dlogging=OFF
	
define Build/InstallDev
	$(INSTALL_DIR) $(1)
	$(CP) $(PKG_INSTALL_DIR)/* $(1)
endef

define Package/rblibtorrent/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/*.so* $(1)/usr/lib
endef

$(eval $(call BuildPackage,rblibtorrent))
