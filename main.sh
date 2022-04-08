#!/bin/bash
function git_sparse_clone() {
branch="$1" rurl="$2" localdir="$3" && shift 3
git clone -b $branch --depth 1 --filter=blob:none --sparse $rurl $localdir
cd $localdir
git sparse-checkout init --cone
git sparse-checkout set $@
mv -n $@ ../
cd ..
rm -rf $localdir
}

function mvdir() {
mv -n `find $1/* -maxdepth 0 -type d` ./
rm -rf $1
}

git clone --depth 1 https://github.com/kenzok78/my-packages && mvdir my-packages
git clone --depth 1 https://github.com/kiddin9/openwrt-bypass && mvdir openwrt-bypass
git clone --depth 1 https://github.com/kiddin9/luci-app-dnsfilter
git clone --depth 1 https://github.com/kiddin9/aria2
git clone --depth 1 https://github.com/kiddin9/luci-app-baidupcs-web
git clone --depth 1 https://github.com/kiddin9/luci-theme-edge
git clone --depth 1 https://github.com/kiddin9/qBittorrent-Enhanced-Edition
git clone --depth 1 https://github.com/kiddin9/autoshare && mvdir autoshare
git clone --depth 1 https://github.com/kiddin9/openwrt-openvpn && mvdir openwrt-openvpn
git clone --depth 1 https://github.com/kiddin9/luci-app-xlnetacc
git clone --depth 1 https://github.com/kiddin9/openwrt-amule-dlp && mvdir openwrt-amule-dlp
git clone --depth 1 https://github.com/kiddin9/luci-app-wizard

git clone --depth 1 https://github.com/xiaorouji/openwrt-passwall
git clone --depth 1 https://github.com/Lienol/openwrt-package
git clone --depth 1 https://github.com/ysc3839/openwrt-minieap
git clone --depth 1 https://github.com/ysc3839/luci-proto-minieap
git clone --depth 1 https://github.com/BoringCat/luci-app-mentohust
git clone --depth 1 https://github.com/BoringCat/luci-app-minieap
git clone --depth 1 https://github.com/peter-tank/luci-app-dnscrypt-proxy2
git clone --depth 1 https://github.com/peter-tank/luci-app-autorepeater
git clone --depth 1 https://github.com/rufengsuixing/luci-app-autoipsetadder
git clone --depth 1 https://github.com/rufengsuixing/luci-app-onliner
git clone --depth 1 https://github.com/rufengsuixing/luci-app-usb3disable

git clone --depth 1 https://github.com/riverscn/openwrt-iptvhelper && mvdir openwrt-iptvhelper
git clone --depth 1 https://github.com/KyleRicardo/MentoHUST-OpenWrt-ipk
git clone --depth 1 https://github.com/NateLol/luci-app-beardropper
git clone --depth 1 https://github.com/yaof2/luci-app-ikoolproxy
git clone --depth 1 https://github.com/project-lede/luci-app-godproxy

git clone --depth 1 https://github.com/tty228/luci-app-serverchan
git clone --depth 1 https://github.com/4IceG/luci-app-sms-tool smstool && mvdir smstool
git clone --depth 1 https://github.com/silime/luci-app-xunlei
git clone --depth 1 https://github.com/BCYDTZ/luci-app-UUGameAcc
git clone --depth 1 https://github.com/ntlf9t/luci-app-easymesh
git clone --depth 1 https://github.com/zzsj0928/luci-app-pushbot
git clone --depth 1 https://github.com/shanglanxin/luci-app-homebridge


git clone --depth 1 https://github.com/esirplayground/luci-app-poweroff
git clone --depth 1 https://github.com/esirplayground/LingTiGameAcc
git clone --depth 1 https://github.com/esirplayground/luci-app-LingTiGameAcc
git clone --depth 1 https://github.com/brvphoenix/luci-app-wrtbwmon wrtbwmon1 && mvdir wrtbwmon1
git clone --depth 1 https://github.com/brvphoenix/wrtbwmon wrtbwmon2 && mvdir wrtbwmon2
git clone --depth 1 https://github.com/jerrykuku/luci-theme-argon
git clone --depth 1 https://github.com/jerrykuku/luci-app-argon-config
git clone --depth 1 https://github.com/jerrykuku/luci-app-vssr
git clone --depth 1 https://github.com/jerrykuku/luci-app-ttnode
git clone --depth 1 https://github.com/jerrykuku/luci-app-jd-dailybonus
git clone --depth 1 https://github.com/jerrykuku/luci-app-go-aliyundrive-webdav
git clone --depth 1 https://github.com/sirpdboy/luci-app-advanced
git clone --depth 1 https://github.com/sirpdboy/luci-app-netdata
git clone --depth 1 https://github.com/sirpdboy/luci-app-poweroffdevice
git clone --depth 1 https://github.com/sirpdboy/luci-app-autotimeset

git clone --depth 1 https://github.com/jefferymvp/luci-app-koolproxyR
git clone --depth 1 https://github.com/wolandmaster/luci-app-rtorrent
git clone --depth 1 https://github.com/NateLol/luci-app-oled
git clone --depth 1 https://github.com/lloyd18/luci-app-npc
git clone --depth 1 https://github.com/hubbylei/luci-app-clash
git clone --depth 1 https://github.com/destan19/OpenAppFilter && mvdir OpenAppFilter
git clone --depth 1 https://github.com/lvqier/luci-app-dnsmasq-ipset
git clone --depth 1 https://github.com/walkingsky/luci-wifidog luci-app-wifidog
git clone --depth 1 https://github.com/CCnut/feed-netkeeper && mvdir feed-netkeeper
git clone --depth 1 https://github.com/sensec/luci-app-udp2raw
git clone --depth 1 https://github.com/LGA1150/openwrt-sysuh3c && mvdir openwrt-sysuh3c
git clone --depth 1 https://github.com/gdck/luci-app-cupsd cupsd1 && mv -n cupsd1/luci-app-cupsd cupsd1/cups/cups ./ ; rm -rf cupsd1
git clone --depth 1 https://github.com/QiuSimons/openwrt-mos && mv -n openwrt-mos/*mosdns ./ ; rm -rf openwrt-mos
git clone --depth 1 https://github.com/sundaqiang/openwrt-packages && mv -n openwrt-packages/luci-* ./; rm -rf openwrt-packages
git clone --depth 1 https://github.com/zxlhhyccc/luci-app-v2raya
git clone --depth 1 https://github.com/kenzok78/openwrt-minisign
git clone --depth 1 https://github.com/kenzok78/luci-theme-argonne
git clone --depth 1 https://github.com/kenzok78/luci-app-argonne-config
git clone --depth 1 https://github.com/kenzok78/luci-app-fileassistant
git clone --depth 1 https://github.com/thinktip/luci-theme-neobird
git clone --depth 1 -b lede https://github.com/pymumu/luci-app-smartdns
git clone --depth 1 -b luci https://github.com/xiaorouji/openwrt-passwall passwall1 && mv -n passwall1/luci-app-passwall  ./; rm -rf passwall1

svn co https://github.com/immortalwrt/luci/trunk/applications/luci-app-filebrowser
svn co https://github.com/immortalwrt/luci/trunk/applications/luci-app-aliddns
svn co https://github.com/Tencent-Cloud-Plugins/tencentcloud-openwrt-plugin-ddns/trunk/tencentcloud_ddns luci-app-tencentddns
svn co https://github.com/Tencent-Cloud-Plugins/tencentcloud-openwrt-plugin-cos/trunk/tencentcloud_cos luci-app-tencentcloud-cos
svn co https://github.com/kenzok8/jell/trunk/luci-app-adguardhome
svn co https://github.com/kenzok8/jell/trunk/adguardhome
svn co https://github.com/kenzok8/jell/trunk/smartdns
svn co https://github.com/kenzok8/litte/trunk/luci-theme-atmaterial_new
svn co https://github.com/kenzok8/litte/trunk/luci-theme-mcat
svn co https://github.com/kenzok8/litte/trunk/luci-theme-tomato
svn co https://github.com/x-wrt/packages/trunk/net/nft-qos
svn co https://github.com/x-wrt/luci/trunk/applications/luci-app-nft-qos
svn co https://github.com/kiddin9/openwrt-packages/trunk/luci-app-diskman
svn co https://github.com/kiddin9/openwrt-packages/trunk/vsftpd-alt
svn co https://github.com/messense/aliyundrive-fuse/trunk/openwrt && mvdir openwrt
svn co https://github.com/messense/openwrt-wiretrustee/trunk/wiretrustee
svn co https://github.com/messense/aliyundrive-webdav/trunk/openwrt aliyundrive && mvdir aliyundrive
svn co https://github.com/linkease/istore/trunk/luci/luci-app-store
svn co https://github.com/linkease/istore-ui/trunk/app-store-ui
svn co https://github.com/linkease/nas-packages/trunk/network/services && mvdir services
svn co https://github.com/linkease/nas-packages-luci/trunk/luci && mvdir luci

svn co https://github.com/Lienol/openwrt-package/branches/other/lean/luci-app-autoreboot
svn co https://github.com/fw876/helloworld/trunk/luci-app-ssr-plus
svn co https://github.com/vernesong/OpenClash/trunk/luci-app-openclash
svn co https://github.com/lisaac/luci-app-dockerman/trunk/applications/luci-app-dockerman
svn co https://github.com/mingxiaoyu/luci-app-cloudflarespeedtest/trunk/applications/luci-app-cloudflarespeedtest
svn co https://github.com/Carseason/openwrt-themedog/trunk/luci/luci-themedog
svn co https://github.com/ophub/luci-app-amlogic/trunk/luci-app-amlogic
svn co https://github.com/doushang/luci-app-shortcutmenu/trunk/luci-app-shortcutmenu
svn co https://github.com/Ysurac/openmptcprouter-feeds/trunk/luci-app-iperf
svn co https://github.com/sirpdboy/netspeedtest/trunk/luci-app-netspeedtest
svn co https://github.com/sbilly/netmaker-openwrt/trunk/netmaker
svn co https://github.com/xiaorouji/openwrt-passwall2/trunk/luci-app-passwall2
svn co https://github.com/openwrt/packages/trunk/net/shadowsocks-libev


git_sparse_clone master "https://github.com/coolsnowwolf/packages" "leanpack" net/miniupnpd net/mwan3 multimedia/UnblockNeteaseMusic-Go \
multimedia/UnblockNeteaseMusic net/amule net/baidupcs-web multimedia/gmediarender net/go-aliyundrive-webdav \
net/qBittorrent-static net/qBittorrent libs/qtbase libs/qttools libs/rblibtorrent \
net/uugamebooster net/verysync net/dnsforwarder net/nps net/microsocks net/tcpping net/redsocks2

git_sparse_clone master "https://github.com/immortalwrt/packages" "immpack" net/sub-web \
net/smartdns net/dnsproxy net/haproxy net/v2raya net/cdnspeedtest \
net/subconverter net/ngrokc net/oscam net/njitclient net/scutclient net/gost net/gowebdav \
admin/bpytop libs/jpcre2 libs/wxbase libs/rapidjson libs/libcron libs/quickjspp libs/toml11 \
utils/cpulimit utils/filebrowser

git_sparse_clone develop "https://github.com/Ysurac/openmptcprouter-feeds" "enmptcp" luci-app-snmpd \
luci-app-packet-capture luci-app-mail msmtp
git_sparse_clone master "https://github.com/x-wrt/com.x-wrt" "x-wrt" natflow lua-ipops luci-app-macvlan

git_sparse_clone openwrt-21.02 "https://github.com/openwrt/openwrt" "21openwrt" package/libs/mbedtls \
git_sparse_clone openwrt-21.02 "https://github.com/openwrt/packages" "21packages" \
net/openvpn utils/cgroupfs-mount utils/coremark net/xray-core net/nginx net/uwsgi net/ddns-scripts admin/netdata
git_sparse_clone openwrt-21.02 "https://github.com/openwrt/openwrt" "21openwrt" package/libs/mbedtls \

mv -n openwrt-passwall/* ./ ; rm -Rf openwrt-passwall
mv -n openwrt-package/* ./ ; rm -Rf openwrt-package

rm -rf ./*/.git & rm -f ./*/.gitattributes
rm -rf ./*/.svn & rm -rf ./*/.github & rm -rf ./*/.gitignore

exit 0

