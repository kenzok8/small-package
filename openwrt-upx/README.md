# openwrt-upx

UPX pacakage for OpenWrt

## Build Guide

- Download and unzip [OpenWrt SDK](https://downloads.openwrt.org/snapshots/targets/)

- In SDK directory, download Makefiles with git:

```sh
  git clone https://github.com/kuoruan/openwrt-upx.git package/openwrt-upx
```

- Build pakcage

```sh
./scripts/feeds update -a
./scripts/feeds install -a

make defconfig # or make menuconfig

make package/upx/{clean,compile} V=s
```

## For Packages that Need UPX Compress

- Add ```upx/host``` to ```PKG_BUILD_DEPENDS```:

```wiki
PKG_BUILD_DEPENDS:=... upx/host
```

- In ```Build/Compile``` stage:

```makefile
define Build/Compile
  ...
  $(STAGING_DIR_HOST)/bin/upx --lzma --best ... # bin files to be compressed
  ...
endef
```
