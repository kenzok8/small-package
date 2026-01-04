include $(TOPDIR)/rules.mk

PKG_NAME:=rblibtorrent
PKG_VERSION:=2.0.11
PKG_RELEASE:=1

PKG_SOURCE:=libtorrent-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/arvidn/libtorrent/tar.gz/v$(PKG_VERSION)?
PKG_HASH:=a317b4b4352bf1b846072dfacee30cd0afccf1ebc04a84273f1ecba930acb802
PKG_BUILD_DIR:=$(BUILD_DIR)/libtorrent-$(PKG_VERSION)

PKG_LICENSE:=BSD
PKG_LICENSE_FILES:=COPYING

PKG_BUILD_FLAGS:=no-mips16
PKG_BUILD_PARALLEL:=1
PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk
include ./boost-version.mk

define Package/rblibtorrent
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=C++ bittorrent library by Rasterbar Software
  URL:=https://www.libtorrent.org
  DEPENDS:= \
		+libatomic +libc +libgcc +libopenssl +libstdcpp +USE_GLIBC:libpthread \
		+boost +boost-program_options \
		$(if $(filter y,$(NEED_BOOST_SYSTEM)),,+boost-system)
  ABI_VERSION:=2.0
endef

define Package/rblibtorrent/description
  Rasterbar libtorrent is a C++ library that aims to be a good alternative to
  all the other bittorrent implementations around. It is a library and not a
  full featured client, although it comes with a working example client.
endef

TARGET_CFLAGS += $(FPIC) -ffunction-sections -fdata-sections
TARGET_LDFLAGS += -Wl,--gc-sections,--as-needed

CMAKE_OPTIONS += \
	-DBUILD_SHARED_LIBS=ON \
	-DCMAKE_BUILD_TYPE=Release \
	-Ddeprecated-functions=OFF \
	-Dlogging=OFF \
	-Dpython-bindings=OFF \
	-Dpython-egg-info=OFF

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include
	$(CP) $(PKG_INSTALL_DIR)/usr/include/libtorrent $(1)/usr/include/
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libtorrent-rasterbar.so* $(1)/usr/lib/
	$(INSTALL_DIR) $(1)/usr/lib/pkgconfig
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/pkgconfig/libtorrent-rasterbar.pc $(1)/usr/lib/pkgconfig/
endef

define Package/rblibtorrent/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/*.so* $(1)/usr/lib
endef

$(eval $(call BuildPackage,rblibtorrent))
