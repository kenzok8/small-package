# luci-proto-minieap
LuCI support for MiniEAP

## Build

First download [OpenWrt SDK](https://downloads.openwrt.org/) for your device.

```sh
cd /path/to/your/sdk
./scripts/feeds update luci
./scripts/feeds install -a
git clone https://github.com/ysc3839/luci-proto-minieap.git package/luci-proto-minieap
make menuconfig # choose `luci-proto-minieap` in section `LuCI` -> `Protocols`
make package/luci-proto-minieap/compile V=s
```
