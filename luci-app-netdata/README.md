luci-app-netdata for OpenWRT/Lede(ÖÐÎÄ)


Install to OpenWRT/LEDE

git clone https://github.com/sirpdboy/luci-app-netdata
cp -r luci-app-netdata LEDE_DIR/package/luci-app-netdata

cd LEDE_DIR
./scripts/feeds update -a
./scripts/feeds install -a

make menuconfig
LuCI  --->
	1. Collections  --->
		<*> luci
	3. Applications  --->
		<*> luci-app-netdata.........................LuCI support for Netdata


make package/new/luci-app-netdata/compile V=s
