#!/bin/sh
cp feeds.conf.default feeds.conf
echo "src-link local_build $(pwd)/local-build" >> ./feeds.conf

./scripts/feeds update -a
make defconfig
./scripts/feeds install -p local_build -f natmap

make package/natmap/compile V=s