#!/bin/bash
function mvdir() {
mv -n `find $1/* -maxdepth 0 -type d` ./
rm -rf $1
}
git clone --depth 1 https://github.com/kiddin9/my-packages && mvdir my-packages
git clone --depth 1 https://github.com/kiddin9/openwrt-bypass && mvdir openwrt-bypass
git clone --depth 1 https://github.com/kiddin9/luci-app-dnsfilter
git clone --depth 1 https://github.com/kiddin9/aria2
git clone --depth 1 https://github.com/kiddin9/luci-app-eqos
git clone --depth 1 https://github.com/kiddin9/luci-app-baidupcs-web
git clone --depth 1 https://github.com/kiddin9/luci-theme-edge
git clone --depth 1 https://github.com/kiddin9/qBittorrent-Enhanced-Edition
git clone --depth 1 https://github.com/kiddin9/autoshare && mvdir autoshare
git clone --depth 1 https://github.com/kiddin9/openwrt-openvpn && mvdir openwrt-openvpn
git clone --depth 1 https://github.com/kiddin9/luci-app-xlnetacc
git clone --depth 1 https://github.com/kiddin9/openwrt-amule-dlp && mvdir openwrt-amule-dlp

git clone --depth 1 https://github.com/xiaorouji/openwrt-passwall
git clone --depth 1 https://github.com/Lienol/openwrt-package
git clone --depth 1 https://github.com/BoringCat/luci-app-mentohust
git clone --depth 1 https://github.com/KyleRicardo/MentoHUST-OpenWrt-ipk
git clone --depth 1 https://github.com/rufengsuixing/luci-app-autoipsetadder
git clone --depth 1 https://github.com/NateLol/luci-app-beardropper
git clone --depth 1 https://github.com/riverscn/openwrt-iptvhelper && mvdir openwrt-iptvhelper
git clone --depth 1 https://github.com/project-lede/luci-app-godproxy
git clone --depth 1 https://github.com/BoringCat/luci-app-minieap
git clone --depth 1 https://github.com/rufengsuixing/luci-app-onliner
git clone --depth 1 https://github.com/tty228/luci-app-serverchan
git clone --depth 1 https://github.com/4IceG/luci-app-sms-tool smstool && mvdir smstool
git clone --depth 1 https://github.com/rufengsuixing/luci-app-usb3disable
git clone --depth 1 https://github.com/silime/luci-app-xunlei
git clone --depth 1 https://github.com/ysc3839/luci-proto-minieap

git clone --depth 1 https://github.com/zzsj0928/luci-app-pushbot
git clone --depth 1 https://github.com/shanglanxin/luci-app-homebridge
git clone --depth 1 https://github.com/jerrykuku/luci-theme-argon
git clone --depth 1 https://github.com/jerrykuku/luci-app-argon-config
git clone --depth 1 https://github.com/jerrykuku/luci-app-vssr
git clone --depth 1 https://github.com/jerrykuku/luci-app-ttnode
git clone --depth 1 https://github.com/jefferymvp/luci-app-koolproxyR
git clone --depth 1 https://github.com/peter-tank/luci-app-dnscrypt-proxy2
git clone --depth 1 https://github.com/sirpdboy/luci-app-advanced
git clone --depth 1 https://github.com/sirpdboy/luci-app-netdata
git clone --depth 1 https://github.com/sirpdboy/luci-app-poweroffdevice
git clone --depth 1 https://github.com/sirpdboy/luci-app-autotimeset
git clone --depth 1 https://github.com/wolandmaster/luci-app-rtorrent
git clone --depth 1 https://github.com/jerrykuku/luci-app-jd-dailybonus
git clone --depth 1 https://github.com/NateLol/luci-app-oled

git clone --depth 1 https://github.com/destan19/OpenAppFilter && mvdir OpenAppFilter
git clone --depth 1 https://github.com/esirplayground/luci-app-poweroff
git clone --depth 1 https://github.com/lvqier/luci-app-dnsmasq-ipset
git clone --depth 1 https://github.com/small-5/ddns-scripts-dnspod
git clone --depth 1 https://github.com/small-5/ddns-scripts-aliyun
git clone --depth 1 https://github.com/walkingsky/luci-wifidog luci-app-wifidog
git clone --depth 1 https://github.com/peter-tank/luci-app-autorepeater
git clone --depth 1 https://github.com/CCnut/feed-netkeeper && mvdir feed-netkeeper
git clone --depth 1 https://github.com/brvphoenix/luci-app-wrtbwmon wrtbwmon1 && mvdir wrtbwmon1
git clone --depth 1 https://github.com/brvphoenix/wrtbwmon wrtbwmon2 && mvdir wrtbwmon2
git clone --depth 1 https://github.com/linkease/ddnsto-openwrt && mvdir ddnsto-openwrt
git clone --depth 1 https://github.com/sensec/luci-app-udp2raw
git clone --depth 1 https://github.com/LGA1150/openwrt-sysuh3c && mvdir openwrt-sysuh3c
git clone --depth 1 https://github.com/gdck/luci-app-cupsd cupsd1 && mv -n cupsd1/luci-app-cupsd cupsd1/cups/cups ./ ; rm -rf cupsd1

svn co https://github.com/Lienol/openwrt/trunk/package/lean/luci-app-autoreboot
svn co https://github.com/fw876/helloworld/trunk/luci-app-ssr-plus
svn co https://github.com/Tencent-Cloud-Plugins/tencentcloud-openwrt-plugin-ddns/trunk/tencentcloud_ddns luci-app-tencentddns
svn co https://github.com/coolsnowwolf/lede/trunk/package/network/services/shellsync
svn co https://github.com/x-wrt/packages/trunk/net/nft-qos
svn co https://github.com/x-wrt/luci/trunk/applications/luci-app-nft-qos
svn co https://github.com/vernesong/OpenClash/trunk/luci-app-openclash
svn co https://github.com/lisaac/luci-app-dockerman/trunk/applications/luci-app-dockerman

svn co https://github.com/doushang/luci-app-shortcutmenu/trunk/luci-app-shortcutmenu
svn co https://github.com/sundaqiang/openwrt-packages/trunk/luci-app-services-wolplus
svn co https://github.com/Ysurac/openmptcprouter-feeds/trunk/luci-app-iperf
svn co https://github.com/sirpdboy/netspeedtest/trunk/luci-app-netspeedtest
svn co https://github.com/messense/aliyundrive-webdav/trunk/openwrt aliyundrive && mvdir aliyundrive

git clone --depth 1 https://github.com/BCYDTZ/luci-app-UUGameAcc
git clone --depth 1 https://github.com/ntlf9t/luci-app-easymesh
svn co https://github.com/frainzy1477/luci-app-clash/trunk ./luci-app-clash
svn co https://github.com/sirpdboy/sirpdboy-package/trunk/luci-app-koolddns
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/microsocks
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/redsocks2
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/tcpping
svn co https://github.com/liuran001/openwrt-theme/trunk/luci-theme-argon-lr
svn co https://github.com/openwrt/packages/trunk/net/shadowsocks-libev
svn co https://github.com/immortalwrt/luci/trunk/applications/luci-app-aliddns
svn co https://github.com/immortalwrt/luci/trunk/applications/luci-app-udp2raw
svn co https://github.com/immortalwrt/packages/trunk/net/udp2raw-tunnel
svn co https://github.com/kenzok8/jell/trunk/luci-app-adguardhome
svn co https://github.com/kenzok8/jell/trunk/adguardhome
svn co https://github.com/immortalwrt/luci/trunk/applications/luci-app-smartdns
svn co https://github.com/immortalwrt/packages/trunk/net/smartdns
svn co https://github.com/kenzok8/litte/trunk/luci-theme-argon_new
svn co https://github.com/kenzok8/litte/trunk/luci-theme-opentopd_new
svn co https://github.com/kenzok8/litte/trunk/luci-theme-atmaterial_new
svn co https://github.com/kenzok8/litte/trunk/luci-theme-mcat
svn co https://github.com/kenzok8/litte/trunk/luci-theme-tomato

svn co https://github.com/immortalwrt/packages/trunk/admin/bpytop
svn co https://github.com/immortalwrt/packages/trunk/libs/jpcre2
svn co https://github.com/immortalwrt/packages/trunk/libs/wxbase
svn co https://github.com/immortalwrt/packages/trunk/libs/libcron
svn co https://github.com/immortalwrt/packages/trunk/libs/rapidjson
svn co https://github.com/immortalwrt/packages/trunk/libs/quickjspp
svn co https://github.com/immortalwrt/packages/trunk/libs/toml11
svn co https://github.com/garypang13/openwrt-packages/trunk/qtbase
svn co https://github.com/garypang13/openwrt-packages/trunk/qttools
svn co https://github.com/garypang13/openwrt-packages/trunk/rblibtorrent

mv -n openwrt-passwall/* ./ ; rm -Rf openwrt-passwall
mv -n openwrt-package/* ./ ; rm -Rf openwrt-package

rm -rf ./*/.git & rm -f ./*/.gitattributes
rm -rf ./*/.svn & rm -rf ./*/.github & rm -rf ./*/.gitignore
exit 0


