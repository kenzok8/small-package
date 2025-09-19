# openwrt-fastfetch

## Releases
You can find the prebuilt-ipks [here](https://fantastic-packages.github.io/packages/) 

## Build

```shell
# Take the x86_64 platform as an example
tar xjf openwrt-sdk-23.05.5-x86-64_gcc-8.4.0_musl.Linux-x86_64.tar.xz
# Go to the SDK root dir
cd OpenWrt-sdk-*-x86_64_*
# First run to generate a .config file
make menuconfig
./scripts/feeds update -a
./scripts/feeds install -a
# Get Makefile
git clone --depth 1 --branch master --single-branch --no-checkout https://github.com/muink/openwrt-fastfetch.git package/fastfetch
pushd package/fastfetch
umask 022
git checkout
popd
# Select the package Utilities -> fastfetch
make menuconfig
# Start compiling
make package/fastfetch/compile V=s BUILD_LOG=y -j$(nproc)
```
