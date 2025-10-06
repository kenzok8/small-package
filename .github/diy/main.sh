#!/bin/bash
function git_clone() {
  git clone --depth 1 $1 $2 || true
 }
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
(
#git clone --depth 1 https://github.com/kenzo78/my-packages && mvdir my-packages
git clone --depth 1 https://github.com/kiddin9/luci-app-dnsfilter
git clone --depth 1 https://github.com/kiddin9/aria2
git clone --depth 1 https://github.com/kiddin9/luci-app-baidupcs-web
#git clone --depth 1 https://github.com/kiddin9/qBittorrent-Enhanced-Edition
git clone --depth 1 https://github.com/kiddin9/autoshare && mvdir autoshare
git clone --depth 1 https://github.com/kiddin9/openwrt-openvpn && mvdir openwrt-openvpn
git clone --depth 1 https://github.com/kiddin9/luci-app-xlnetacc
git clone --depth 1 https://github.com/kiddin9/luci-app-wizard
git clone --depth 1 -b 18.06 https://github.com/kiddin9/luci-theme-edge
git clone --depth 1 https://github.com/derisamedia/luci-theme-alpha
git clone --depth 1 https://github.com/animegasan/luci-app-alpha-config
git clone --depth 1 https://github.com/yichya/luci-app-xray
git clone --depth 1 https://github.com/Lienol/openwrt-package
git clone --depth 1 https://github.com/ysc3839/openwrt-minieap
git clone --depth 1 https://github.com/ysc3839/luci-proto-minieap
git clone --depth 1 https://github.com/BoringCat/luci-app-mentohust
git clone --depth 1 https://github.com/BoringCat/luci-app-minieap
git clone --depth 1 https://github.com/peter-tank/luci-app-dnscrypt-proxy2
git clone --depth 1 https://github.com/peter-tank/luci-app-autorepeater
git clone --depth 1 https://github.com/rufengsuixing/luci-app-autoipsetadder
git clone --depth 1 https://github.com/ElvenP/luci-app-onliner
git clone --depth 1 https://github.com/rufengsuixing/luci-app-usb3disable
git clone --depth 1 https://github.com/riverscn/openwrt-iptvhelper && mvdir openwrt-iptvhelper
git clone --depth 1 https://github.com/KyleRicardo/MentoHUST-OpenWrt-ipk
git clone --depth 1 https://github.com/NateLol/luci-app-beardropper
git clone --depth 1 https://github.com/yaof2/luci-app-ikoolproxy
git clone --depth 1 https://github.com/project-lede/luci-app-godproxy
git clone --depth 1 https://github.com/tty228/luci-app-wechatpush
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
#git clone --depth 1 https://github.com/jerrykuku/luci-app-argon-config
#git clone --depth 1 https://github.com/jerrykuku/luci-app-vssr
git clone --depth 1 https://github.com/jerrykuku/luci-app-ttnode
#git clone --depth 1 https://github.com/jerrykuku/luci-app-jd-dailybonus
git clone --depth 1 https://github.com/jerrykuku/luci-app-go-aliyundrive-webdav
git clone --depth 1 https://github.com/jerrykuku/lua-maxminddb
git clone --depth 1 https://github.com/sirpdboy/luci-app-advanced
git clone --depth 1 https://github.com/sirpdboy/luci-theme-opentopd
git clone --depth 1 https://github.com/sirpdboy/luci-app-poweroffdevice
git clone --depth 1 https://github.com/sirpdboy/luci-app-autotimeset
git clone --depth 1 https://github.com/sirpdboy/luci-app-lucky lucik && mv -n lucik/luci-app-lucky ./ ; rm -rf lucik
git clone --depth 1 https://github.com/sirpdboy/luci-app-partexp
git clone --depth 1 https://github.com/sirpdboy/luci-app-netdata
git clone --depth 1 https://github.com/sirpdboy/luci-app-chatgpt-web
git clone --depth 1 https://github.com/sirpdboy/luci-app-eqosplus 
git clone --depth 1 https://github.com/sirpdboy/luci-app-ddns-go ddnsgo && mv -n ddnsgo/luci-app-ddns-go ./; rm -rf ddnsgo
git clone --depth 1 https://github.com/sirpdboy/netspeedtest speedtest && mv -f speedtest/*/ ./ && rm -rf speedtest
#git clone --depth 1 https://github.com/Jason6111/luci-app-netdata
git clone --depth 1 https://github.com/KFERMercer/luci-app-tcpdump
git clone --depth 1 https://github.com/jefferymvp/luci-app-koolproxyR
git clone --depth 1 https://github.com/wolandmaster/luci-app-rtorrent
git clone --depth 1 https://github.com/NateLol/luci-app-oled
git clone --depth 1 https://github.com/hubbylei/luci-app-clash
git clone --depth 1 https://github.com/destan19/OpenAppFilter && mvdir OpenAppFilter
git clone --depth 1 https://github.com/lvqier/luci-app-dnsmasq-ipset
git clone --depth 1 https://github.com/walkingsky/luci-wifidog luci-app-wifidog
git clone --depth 1 https://github.com/CCnut/feed-netkeeper && mvdir feed-netkeeper
git clone --depth 1 https://github.com/sensec/luci-app-udp2raw
git clone --depth 1 https://github.com/LGA1150/openwrt-sysuh3c && mvdir openwrt-sysuh3c
git clone --depth 1 https://github.com/Hyy2001X/AutoBuild-Packages && rm -rf AutoBuild-Packages/luci-app-adguardhome && mvdir AutoBuild-Packages
git clone --depth 1 https://github.com/lisaac/luci-app-dockerman dockerman && mv -n dockerman/applications/* ./; rm -rf dockerman
git clone --depth 1 https://github.com/gdck/luci-app-cupsd cupsd1 && mv -n cupsd1/luci-app-cupsd cupsd1/cups/cups ./ ; rm -rf cupsd1
git clone --depth 1 https://github.com/kenzok8/wall && mv -n wall/* ./ ; rm -rf wall
git clone --depth 1 https://github.com/peter-tank/luci-app-fullconenat
git clone --depth 1 https://github.com/sirpdboy/sirpdboy-package && mv -n sirpdboy-package/luci-app-dockerman ./ ; rm -rf sirpdboy-package
git clone --depth 1 https://github.com/sundaqiang/openwrt-packages && mv -n openwrt-packages/luci-* ./; rm -rf openwrt-packages
git clone --depth 1 https://github.com/zxlhhyccc/luci-app-v2raya
git clone --depth 1 https://github.com/kenzok8/luci-theme-ifit ifit && mv -n ifit/luci-theme-ifit ./;rm -rf ifit
git clone --depth 1 https://github.com/kenzok78/openwrt-minisign
git clone --depth 1 https://github.com/kenzok78/luci-theme-argone
git clone --depth 1 https://github.com/kenzok78/luci-app-argone-config
git clone --depth 1 https://github.com/kenzok78/luci-app-adguardhome
git clone --depth 1 https://github.com/kenzok78/luci-theme-design
git clone --depth 1 https://github.com/kenzok78/luci-app-design-config
git clone --depth 1 -b lede https://github.com/pymumu/luci-app-smartdns
git clone --depth 1 https://github.com/ophub/luci-app-amlogic amlogic && mv -n amlogic/luci-app-amlogic ./;rm -rf amlogic
git clone --depth 1 https://github.com/linkease/nas-packages && mv -n nas-packages/{network/services/*,multimedia/*} ./; rm -rf nas-packages
git clone --depth 1 https://github.com/linkease/nas-packages-luci && mv -n nas-packages-luci/luci/* ./; rm -rf nas-packages-luci
git clone --depth 1 https://github.com/linkease/istore && mv -n istore/luci/* ./; rm -rf istore
git clone --depth 1 https://github.com/AlexZhuo/luci-app-bandwidthd
git clone --depth 1 https://github.com/linkease/openwrt-app-actions
git clone --depth 1 https://github.com/ZeaKyX/luci-app-speedtest-web
git clone --depth 1 https://github.com/ZeaKyX/speedtest-web
git clone --depth 1 https://github.com/Zxilly/UA2F
git clone --depth 1 https://github.com/Huangjoe123/luci-app-eqos
git clone --depth 1 https://github.com/honwen/luci-app-aliddns
git clone --depth 1 https://github.com/immortalwrt/homeproxy luci-app-homeproxy
#git clone --depth 1 https://github.com/muink/luci-app-homeproxy
git clone --depth 1 https://github.com/muink/luci-app-dnsproxy
git clone --depth 1 https://github.com/ximiTech/luci-app-msd_lite
git clone --depth 1 -b master https://github.com/UnblockNeteaseMusic/luci-app-unblockneteasemusic
git clone --depth 1 https://github.com/sbwml/luci-app-alist openwrt-alist && mv -n openwrt-alist/*alist ./ ; rm -rf openwrt-alist
git clone --depth 1 https://github.com/sbwml/luci-app-qbittorrent openwrt-qb && mv -n openwrt-qb/* ./ ; rm -rf openwrt-qb
git clone --depth 1 https://github.com/vernesong/OpenClash && mv -n OpenClash/luci-app-openclash ./; rm -rf OpenClash
git clone --depth 1 https://github.com/messense/aliyundrive-webdav aliyundrive && mv -n aliyundrive/openwrt/* ./ ; rm -rf aliyundrive
git clone --depth 1 https://github.com/messense/aliyundrive-fuse aliyundrive && mv -n aliyundrive/openwrt/* ./;rm -rf aliyundrive
git clone --depth 1 https://github.com/kenzok8/litte && mv -n litte/luci-theme-atmaterial_new litte/luci-theme-tomato ./ ; rm -rf litte
git clone --depth 1 https://github.com/fw876/helloworld && mv -n helloworld/luci-app-ssr-plus ./ ; rm -rf helloworld
#git clone --depth 1 https://github.com/QiuSimons/openwrt-mos && mv -n openwrt-mos/luci-app-mosdns ./ ; rm -rf openwrt-mos
git clone --depth 1 https://github.com/sbwml/luci-app-mosdns openwrt-mos && mv -n openwrt-mos/{*mosdns,v2dat} ./; rm -rf openwrt-mos
git clone --depth 1 https://github.com/xiaorouji/openwrt-passwall2 passwall2 && mv -n passwall2/luci-app-passwall2 ./;rm -rf passwall2
git clone --depth 1 https://github.com/xiaorouji/openwrt-passwall passwall1 && mv -n passwall1/luci-app-passwall  ./; rm -rf passwall1
git clone --depth 1 https://github.com/SSSSSimon/tencentcloud-openwrt-plugin-ddns && mv -n tencentcloud-openwrt-plugin-ddns/tencentcloud_ddns ./luci-app-tencentddns; rm -rf tencentcloud-openwrt-plugin-ddns
git clone --depth 1 https://github.com/Tencent-Cloud-Plugins/tencentcloud-openwrt-plugin-cos && mv -n tencentcloud-openwrt-plugin-cos/tencentcloud_cos ./luci-app-tencentcloud-cos; rm -rf tencentcloud-openwrt-plugin-cos
git clone --depth 1 https://github.com/kiddin9/kwrt-packages && mv -n kwrt-packages/luci-app-bypass kwrt-packages/luci-app-fileassistant ./ ; rm -rf kwrt-packages
git clone --depth 1 https://github.com/immortalwrt/packages && mv -n packages/net/{cdnspeedtest,dae,daed,vsftpd,transmission} ./ ; rm -rf packages
git clone --depth 1 https://github.com/immortalwrt/luci && mv -n luci/applications/{luci-app-argon-config,luci-app-dae,luci-app-diskman,luci-app-filebrowser-go,luci-app-daed,luci-app-filebrowser,luci-app-gost,luci-app-usb-printer,luci-app-openlist,luci-app-vlmcsd,luci-app-transmission,luci-app-snmpd} ./ ; rm -rf luci
git clone --depth 1 https://github.com/mingxiaoyu/luci-app-cloudflarespeedtest cloudflarespeedtest && mv -n cloudflarespeedtest/applications/* ./;rm -rf cloudflarespeedtest
git clone --depth 1 https://github.com/doushang/luci-app-shortcutmenu luci-shortcutmenu && mv -n luci-shortcutmenu/luci-app-shortcutmenu ./ ; rm -rf luci-shortcutmenu
git clone --depth 1 https://github.com/sbilly/netmaker-openwrt && mv -n netmaker-openwrt/netmaker ./; rm -rf netmaker-openwrt
#git clone --depth 1 https://github.com/coolsnowwolf/packages && mv -n packages/multimedia/UnblockNeteaseMusic-Go packages/net/msd_lite ./ ; rm -rf packages
#git clone --depth 1 https://github.com/coolsnowwolf/luci && mv -n luci/applications/luci-app-unblockmusic luci/libs/luci-lib-fs./ ; rm -rf luci
git clone --depth 1 https://github.com/gSpotx2f/luci-app-internet-detector
git clone --depth 1 https://github.com/vinewx/NanoHatOLED; mv NanoHatOLED/nanohatoled ./;rm -rf NanoHatOLED
git clone --depth 1 https://github.com/zerolabnet/luci-app-torbp
git clone --depth 1 https://github.com/muink/luci-app-tinyfilemanager
git clone --depth 1 https://github.com/sbwml/luci-app-airconnect airconnect1 && mv airconnect1/* ./ && rm -rf airconnect1
#git clone --depth 1 https://github.com/sirpdboy/luci-theme-kucat -b js --depth 1
git clone --depth 1 https://github.com/blueberry-pie-11/luci-app-natmap
git clone --depth 1 https://github.com/QiuSimons/luci-app-daed-next daed1 && mvdir daed1
#git clone --depth 1 https://github.com/morytyann/OpenWrt-mihomo OpenWrt-mihomo && mv -n OpenWrt-mihomo/*mihomo ./ ; rm -rf OpenWrt-mihomo
git clone --depth 1 https://github.com/nikkinikki-org/OpenWrt-momo OpenWrt-momo && mv -n OpenWrt-momo/*momo ./ ; rm -rf OpenWrt-momo
git clone --depth 1 https://github.com/nikkinikki-org/OpenWrt-nikki OpenWrt-nikki && mv -n OpenWrt-nikki/*nikki ./ ; rm -rf OpenWrt-nikki
git clone --depth 1 https://github.com/muink/openwrt-fchomo openwrt-fchomo && mv -n openwrt-fchomo/*homo ./ ; rm -rf openwrt-fchomo
git clone --depth 1 https://github.com/lucikap/luci-app-brukamen && mv -n luci-app-brukamen/{luci*,mentohust,iii/*} ./;rm -rf luci-app-brukamen luci-app-autoshell_*.ipk
git clone --depth 1 -b nekobox https://github.com/Thaolga/openwrt-nekobox && mv openwrt-nekobox/luci-app-nekobox ./;rm -rf openwrt-nekobox
git clone --depth 1 https://github.com/Carseason/openwrt-packages Carseason && mv -n Carseason/*/* ./;mv services/routergo ./;rm -rf Carseason
git clone --depth 1 https://github.com/Carseason/openwrt-themedog && mv -n openwrt-themedog/luci/* ./;rm -rf openwrt-themedog
git clone --depth 1 https://github.com/Carseason/openwrt-app-actions Carseason && mv -n Carseason/applications/* ./;rm -rf Carseason
git clone --depth 1 https://github.com/Akimio521/luci-app-gecoosac
git clone --depth 1 https://github.com/EasyTier/luci-app-easytier
git clone --depth 1 https://github.com/asvow/luci-app-tailscale
git clone --depth 1 https://github.com/kiddin9/openwrt-netdata netdata
git clone --depth 1 https://github.com/kiddin9/openwrt-my-dnshelper && mvdir openwrt-my-dnshelper
git clone --depth 1 https://github.com/kiddin9/openwrt-lingtigameacc && mvdir openwrt-lingtigameacc
git clone --depth 1 https://github.com/kiddin9/luci-app-timewol
git clone --depth 1 https://github.com/kiddin9/luci-app-vsftpd
git clone --depth 1 https://github.com/kiddin9/openwrt-subconverter && mvdir openwrt-subconverter
git clone --depth 1 https://github.com/kiddin9/luci-app-syncdial
git clone --depth 1 https://github.com/sbwml/luci-app-webdav
git clone --depth 1 https://github.com/sirpdboy/luci-app-taskplan taskplan && mvdir taskplan
git clone --depth 1 https://github.com/sirpdboy/luci-app-watchdog watchdog1 && mvdir watchdog1
git clone --depth 1 https://github.com/sirpdboy/luci-app-timecontrol timecontrol && mvdir timecontrol
git clone --depth 1 https://github.com/sirpdboy/luci-theme-kucat openwrt-kucat && mv -n openwrt-kucat/luci-theme-kucat ./ ; rm -rf openwrt-kucat
git clone --depth 1 https://github.com/muink/openwrt-fastfetch
git clone --depth 1 https://github.com/linkease/lcdsimple lcdsimple1 && mvdir lcdsimple1
git clone --depth 1 https://github.com/Wulnut/luci-app-suselogin
git clone https://github.com/Ausaci/luci-app-nat6-helper -b main-dev
git clone --depth 1 https://github.com/animegasan/luci-app-droidmodem
git clone --depth 1 https://github.com/kenzok78/luci-app-guest-wifi
git clone --depth 1 https://github.com/EkkoG/openwrt-natmap
git clone --depth 1 https://github.com/EkkoG/luci-app-natmap
git clone --depth 1 https://github.com/EasyTier/luci-app-easytier luci-app-easytier1 && mvdir luci-app-easytier1
git clone --depth 1 https://github.com/sbwml/luci-app-openlist2 oplist && mvdir oplist
git clone --depth 1 https://github.com/AngelaCooljx/luci-theme-material3
git clone --depth 1 https://github.com/vison-v/luci-app-nginx-proxy
) &
(
git_sparse_clone master "https://github.com/coolsnowwolf/packages" multimedia/UnblockNeteaseMusic-Go \
multimedia/aliyundrive-webdav net/gowebdav net/kismet net/mstpd \
net/qBittorrent-static net/phtunnel net/headscale net/clouddrive2 net/baidupcs-go net/daemonlogger net/geth net/gnurl \
net/uugamebooster net/pgyvpn net/ooniprobe net/polipo net/rosy-file-server net/qiyougamebooster \
net/sqm-scripts-extra net/tor-fw-helper net/vncrepeater net/verysync \
net/vpnbypass net/vpn-policy-routing utils/qfirehose
git_sparse_clone master "https://github.com/lunatickochiya/Matrix-Action-Openwrt" package/kochiya/brlaser package/kochiya/luci-app-banmac-ipt package/kochiya/luci-app-banmac-nft package/kochiya/luci-app-nvr package/kochiya/luci-app-openvpn-server package/kochiya/luci-app-openvpn-server-client
git_sparse_clone main https://github.com/sbwml/openwrt_pkgs luci-app-socat
) &
(
git_sparse_clone master "https://github.com/xiaoqingfengATGH/feeds-xiaoqingfeng" homeredirect luci-app-homeredirect
git_sparse_clone master "https://github.com/immortalwrt/immortalwrt" \
package/kernel/rtl8189es package/emortal/autocore package/emortal/automount \
package/network/utils/fullconenat package/emortal/cpufreq package/network/utils/fullconenat-nft \
package/utils/mhz package/utils/pcat-manager
) &
(
git_sparse_clone master "https://github.com/x-wrt/com.x-wrt" luci-app-macvlan luci-app-xwan
git_sparse_clone master "https://github.com/obsy/packages" oscam luci-proto-wwan 3ginfo modemband
) &
(
git_sparse_clone develop "https://github.com/Ysurac/openmptcprouter-feeds" \
dsvpn glorytun-udp glorytun grpcurl ipcalc luci-app-dsvpn luci-app-glorytun-tcp luci-app-glorytun-udp luci-app-mail luci-app-mlvpn luci-app-mptcp luci-app-nginx-ha luci-app-sqm-autorate luci-app-packet-capture luci-app-iperf luci-theme-openmptcprouter sqm-autorate speedtestc mlvpn mptcp systemtap tcptraceroute tracebox tsping atinout z8102
git_sparse_clone chawrt/24.10 "https://github.com/liudf0716/luci" applications/luci-app-yt-dlp applications/luci-app-apfree-wifidog applications/luci-app-ss-redir
git_sparse_clone chawrt/24.10 "https://github.com/liudf0716/packages" net/ss-redir
) &

wait

git_sparse_clone master "https://github.com/immortalwrt/packages" net/n2n net/dae \
net/amule net/cdnspeedtest net/minieap net/sysuh3c net/3proxy net/cloudreve \
net/go-nats net/go-wol net/bitsrunlogin-go net/transfer net/daed net/udp2raw net/msd_lite \
net/subconverter net/ngrokc net/scutclient net/ua2f net/dufs net/qBittorrent-Enhanced-Edition \
net/tinyportmapper net/tinyfecvpn net/nexttrace net/rustdesk-server net/tuic-server \
net/ipset-lists net/ShadowVPN net/nps net/vlmcsd net/dnsforwarder \
net/ps3netsrv net/q net/speedtest-cli \
net/vsftpd net/miniupnpd net/p910nd \
net/ariang libs/wxbase libs/rapidjson libs/libcron libs/quickjspp libs/toml11 \
libs/libdouble-conversion libs/qt6base libs/jpcre2 libs/alac libs/libcryptopp libs/antileech \
utils/qt6tools utils/cpulimit utils/sendat utils/cups-bjnp utils/rhash utils/boltbrowser \
utils/phicomm-k3screenctrl utils/joker utils/7z utils/dhrystone utils/supervisor utils/tinymembench utils/pcat-mgr utils/fan2go \
utils/coremark utils/watchcat multimedia/you-get multimedia/lux multimedia/gmediarender multimedia/ykdl multimedia/gallery-dl \
sound/spotifyd devel/go-rice admin/gotop \
lang/lua-periphery lang/lua-neturl lang/lua-maxminddb lang/node-pnpm
#git_clone https://github.com/koshev-msk/modemfeed && mv -n modemfeed/*/!(telephony)/* ./; rm -rf modemfeed
git_sparse_clone openwrt-24.10 "https://github.com/coolsnowwolf/luci" applications themes/luci-theme-design libs/luci-lib-fs
mv -f applications luciapp;rm -rf luciapp/luci-app-turboacc
git_sparse_clone master "https://github.com/coolsnowwolf/luci" applications
mv -n applications/* luciapp/; rm -rf applications
rm -rf luciapp/{luci-app-qbittorrent,luci-app-zerotier,luci-app-cpufreq,luci-app-e2guardian,luci-app-aliyundrive-fuse,luci-app-syncdial,luci-app-firewall}
git_sparse_clone openwrt-24.10 "https://github.com/immortalwrt/luci" applications protocols/luci-proto-minieap protocols/luci-proto-quectel themes/luci-theme-argon
shopt -s extglob
mv -n luciapp/!(luci-app-filetransfer|luci-app-ksmbd) applications/
rm -rf luciapp

for ipk in $(ls -d applications/!(luci-app-rclone|luci-app-dockerman|luci-app-3ginfo-lite|luci-app-aria2|luci-app-ddns|luci-app-package-manager|luci-app-ksmbd|luci-app-samba4|luci-app-watchcat|luci-app-upnp|luci-app-transmission)/); do
	if [[ $(ls $ipk/po | wc -l) -gt 4 ]]; then
	rm -rf $ipk
	fi
done

#mv -n openwrt-passwall/* ./ ; rm -Rf openwrt-passwall
rm -rf openssl
mv -n openwrt-package/* ./ ; rm -Rf openwrt-package
mv -n openwrt-app-actions/applications/* ./;rm -rf openwrt-app-actions
sed -i \
-e 's?include \.\./\.\./\(lang\|devel\)?include $(TOPDIR)/feeds/packages/\1?' \
-e 's?2. Clash For OpenWRT?3. Applications?' \
-e 's?\.\./\.\./luci.mk?$(TOPDIR)/feeds/luci/luci.mk?' \
-e 's/ca-certificates/ca-bundle/' \
-e 's/php7/php8/g' \
-e 's/+docker /+docker +dockerd /g' \
*/Makefile

sed -i 's/PKG_VERSION:=20240302/PKG_VERSION:=20240223/g; s/PKG_RELEASE:=$(AUTORELESE)/PKG_RELEASE:=1/g' webd/Makefile
sed -i 's/luci-lib-ipkg/luci-base/g' luci-app-store/Makefile
sed -i "/minisign:minisign/d" luci-app-dnscrypt-proxy2/Makefile
sed -i 's/+dockerd/+dockerd +cgroupfs-mount/' luci-app-docker*/Makefile
sed -i '$i /etc/init.d/dockerd restart &' luci-app-docker*/root/etc/uci-defaults/*
sed -i 's/+libcap /+libcap +libcap-bin /' luci-app-openclash/Makefile
sed -i 's/\(+luci-compat\)/\1 +luci-theme-argon/' luci-app-argon-config/Makefile
sed -i 's/\(+luci-compat\)/\1 +luci-theme-design/' luci-app-design-config/Makefile
sed -i 's/\(+luci-compat\)/\1 +luci-theme-argone/' luci-app-argone-config/Makefile
sed -i 's/+vsftpd-alt$/+vsftpd/' luci-app-tencentcloud-cos/Makefile
sed -i 's/ +uhttpd-mod-ubus//' luci-app-packet-capture/Makefile
sed -i 's/	ip.neighbors/	luci.ip.neighbors/' luci-app-wifidog/luasrc/model/cbi/wifidog/wifidog_cfg.lua
#sed -i -e 's/nas/services/g' -e 's/NAS/Services/g' $(grep -rl 'nas\|NAS' luci-app-fileassistant)
#sed -i -e 's/nas/services/g' -e 's/NAS/Services/g' $(grep -rl 'nas\|NAS' luci-app-alist)
sed -i 's/USE_QUIC=1/USE_QUIC=/g' haproxy/Makefile
#find . -type f -name Makefile -exec sed -i 's/PKG_BUILD_FLAGS:=no-mips16/PKG_USE_MIPS16:=0/g' {} +
sed -i '/entry({"admin", "nas"}, firstchild(), "NAS", 45).dependent = false/d; s/entry({"admin", "network", "eqos"}, cbi("eqos"), _("EQoS"))/entry({"admin", "network", "eqos"}, cbi("eqos"), _("EQoS"), 121).dependent = true/' luci-app-eqos/luasrc/controller/eqos.lua
#sed -i '65,73d' adguardhome/Makefile
sed -i 's/PKG_SOURCE_DATE:=2/PKG_SOURCE_DATE:=3/' transmission-web-control/Makefile
find . -type f -name "update.sh" -exec rm -f {} \;
rm -rf adguardhome/patches
exit 0

