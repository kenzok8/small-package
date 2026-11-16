#!/bin/sh
cp feeds.conf.default feeds.conf

# sed -e 's,https://git.openwrt.org,https://github.com,g' \
#     -i.bak feeds.conf


mkdir local-build-packages
cp -r local-build/* local-build-packages/
sed -i '/luci.mk/ c\include $(TOPDIR)/feeds/luci/luci.mk' ./local-build-packages/luci-app-natmap/Makefile

echo "src-link local_build $(pwd)/local-build-packages" >> ./feeds.conf
./scripts/feeds update -a
make defconfig
./scripts/feeds install -p local_build -f -a

make package/luci-app-natmap/compile V=s