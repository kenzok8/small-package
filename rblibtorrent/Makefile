include $(TOPDIR)/rules.mk

PKG_NAME:=rblibtorrent
PKG_VERSION:=2.0.10
PKG_RELEASE:=1

PKG_SOURCE:=libtorrent-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/arvidn/libtorrent/tar.gz/v$(PKG_VERSION)?
PKG_HASH:=3f1a489ac520d89b051a254e453c82535ea0f73457a4686281c9031107c3a9ac
PKG_BUILD_DIR:=$(BUILD_DIR)/libtorrent-$(PKG_VERSION)

PKG_LICENSE:=BSD
PKG_LICENSE_FILES:=COPYING

PKG_USE_MIPS16:=0
PKG_BUILD_FLAGS:=no-mips16
PKG_BUILD_PARALLEL:=1
PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/rblibtorrent
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=C++ bittorrent library by Rasterbar Software
  URL:=https://www.libtorrent.org
  DEPENDS:=+boost +boost-system +libatomic +libc +libgcc +libopenssl +libstdcpp +USE_GLIBC:libpthread
  ABI_VERSION:=2.0
endef

define Package/rblibtorrent/description
  Rasterbar libtorrent is a C++ library that aims to be a good alternative to
  all the other bittorrent implementations around. It is a library and not a
  full featured client, although it comes with a working example client.
endef

TRY_SIGNAL_VERSION:=751a7e5a5be14892bcfdff1e63c653bcbf71cf39
TRY_SIGNAL_FILE:=$(PKG_NAME)-try_signal-$(TRY_SIGNAL_VERSION).tar.xz
define Download/try_signal
	VERSION:=$(TRY_SIGNAL_VERSION)
	SUBDIR:=deps/try_signal
	FILE:=$(TRY_SIGNAL_FILE)
	URL:=https://github.com/arvidn/try_signal.git
	MIRROR_HASH:=32a432e35e81c79f21c49744f00696c112e0deab45d15d91c61ceb63fe25a5f8
	PROTO:=git
endef

$(eval $(call Download,try_signal))

define Build/Prepare
	$(Build/Prepare/Default)
	xzcat $(DL_DIR)/$(TRY_SIGNAL_FILE) | tar -C $(PKG_BUILD_DIR) $(TAR_OPTIONS)
endef

TARGET_CFLAGS += $(FPIC) -ffunction-sections -fdata-sections
TARGET_LDFLAGS += -Wl,--gc-sections,--as-needed

CMAKE_OPTIONS += \
	-DBUILD_SHARED_LIBS=ON \
	-DCMAKE_BUILD_TYPE=Release \
	-Ddeprecated-functions=OFF \
	-Dlogging=OFF \
	-DCMAKE_CXX_STANDARD=17 \
	-Dpython-bindings=$(if $(CONFIG_PACKAGE_python3-libtorrent),ON,OFF) \
	-Dpython-egg-info=$(if $(CONFIG_PACKAGE_python3-libtorrent),ON,OFF)

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
