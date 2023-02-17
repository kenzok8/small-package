module("luci.model.cbi.gpsysupgrade.sysupgrade", package.seeall)
local fs = require "nixio.fs"
local sys = require "luci.sys"
local util = require "luci.util"
local i18n = require "luci.i18n"
local api = require "luci.model.cbi.gpsysupgrade.api"

function get_system_version()
	local system_version = luci.sys.exec("[ -f '/etc/openwrt_version' ] && echo -n `cat /etc/openwrt_version`")
    return system_version
end

function check_update()
		needs_update, notice, md5 = false, false, false
		remote_version = luci.sys.exec("curl -skfL https://op.supes.top/firmware/" ..model.. "/version.txt")
		updatelogs = luci.sys.exec("curl -skfL https://op.supes.top/firmware/updatelogs.txt")
		remoteformat = luci.sys.exec("date -d $(echo \"" ..remote_version.. "\" | tr '\r\n' ',' | awk -F, '{printf $1}' | awk -F. '{printf $3\"-\"$1\"-\"$2}') +%s")
		fnotice = luci.sys.exec("echo \"" ..remote_version.. "\" | tr '\r\n' ',' | awk -F, '{printf $(NF-1)}'")
		md5 = luci.sys.exec("echo \"" ..remote_version.. "\" | tr '\r\n' ',' | awk -F, '{printf $2}'")
		remote_version = luci.sys.exec("echo \"" ..remote_version.. "\" | tr '\r\n' ',' | awk -F, '{printf $1}' | awk -F. '{printf $1\".\"$2\".\"$3}'")
		if remoteformat > sysverformat then
			needs_update = true
			if currentTimeStamp > remoteformat or fnotice == "1" then
				notice = true
			end
		end
end

function to_check()
    if not board_name or board_name == "" then board_name = api.auto_get_board_name() end
	sysverformat = luci.sys.exec("date -d $(echo " ..get_system_version().. " | awk -F. '{printf $3\"-\"$1\"-\"$2}') +%s")
	currentTimeStamp = luci.sys.exec("expr $(date -d \"$(date '+%Y-%m-%d %H:%M:%S')\" +%s) - 172800")
    if board_name == "x86_64" then
    	model = "x86_64"
    	check_update()
    	if fs.access("/sys/firmware/efi") then
    		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-x86-64-generic-squashfs-combined-efi.img.gz"
    	else
    		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-x86-64-generic-squashfs-combined.img.gz"
    		md5 = ""
    	end
    elseif board_name == "x86_generic" then
    	model = "x86_32"
    	check_update()
    	if fs.access("/sys/firmware/efi") then
    		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-x86-generic-squashfs-combined-efi.img.gz"
    	else
    		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-x86-generic-squashfs-combined.img.gz"
    		md5 = ""
    	end
    elseif board_name:match("nanopi%-r2s$") then
		model = "rockchip_armv8/friendlyarm_nanopi-r2s"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-rockchip-armv8-friendlyarm_nanopi-r2s-squashfs-sysupgrade.img.gz"
    elseif board_name:match("nanopi%-r4s$") then
		model = "rockchip_armv8/friendlyarm_nanopi-r4s"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-rockchip-armv8-friendlyarm_nanopi-r4s-squashfs-sysupgrade.img.gz"
    elseif board_name:match("nanopi%-r5s$") then
		model = "rockchip_armv8/friendlyarm_nanopi-r5s"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-rockchip-armv8-friendlyarm_nanopi-r5s-squashfs-sysupgrade.img.gz"
    elseif board_name:match("nanopi%-r4se$") then
		model = "rockchip_armv8/friendlyarm_nanopi-r4se"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-rockchip-armv8-friendlyarm_nanopi-r4se-squashfs-sysupgrade.img.gz"
    elseif board_name:match("fastrhino,r68s$") then
		model = "rockchip_armv8/fastrhino_r68s"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-rockchip-armv8-fastrhino_r68s-squashfs-sysupgrade.img.gz"
    elseif board_name:match("fastrhino,r66s$") then
		model = "rockchip_armv8/fastrhino_r66s"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-rockchip-armv8-fastrhino_r66s-squashfs-sysupgrade.img.gz"
    elseif board_name:match("opc%-h68k$") then
		model = "rockchip_armv8/hinlink_opc-h68k"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-rockchip-armv8-hinlink_opc-h68k-squashfs-sysupgrade.img.gz"
    elseif board_name:match("nanopi%-r2c$") then
		model = "rockchip_armv8/friendlyarm_nanopi-r2c"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-rockchip-armv8-friendlyarm_nanopi-r2c-squashfs-sysupgrade.img.gz"
    elseif board_name:match("doornet2$") then
		model = "rockchip_armv8/embedfire_doornet2"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-rockchip-armv8-embedfire_doornet2-squashfs-sysupgrade.img.gz"
    elseif board_name:match("doornet1$") then
		model = "rockchip_armv8/embedfire_doornet1"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-rockchip-armv8-embedfire_doornet1-squashfs-sysupgrade.img.gz"
    elseif board_name:match("r1%-plus%-lts$") then
		model = "rockchip_armv8/xunlong_orangepi-r1-plus-lts"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-rockchip-armv8-xunlong_orangepi-r1-plus-lts-squashfs-sysupgrade.img.gz"
    elseif board_name:match("orangepi%-r1%-plus$") then
		model = "rockchip_armv8/xunlong_orangepi-r1-plus"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-rockchip-armv8-xunlong_orangepi-r1-plus-squashfs-sysupgrade.img.gz"
    elseif board_name:match("ariaboard,photonicat$") then
		model = "rockchip_armv8/ariaboard_photonicat"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-rockchip-armv8-ariaboard_photonicat-squashfs-sysupgrade.img.gz"
    elseif board_name:match("nanopi%-neo3$") then
		model = "rockchip_armv8/friendlyarm_nanopi-neo3"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-rockchip-armv8-nanopi-neo3-squashfs-sysupgrade.img.gz"
    elseif board_name:match("rpi%-4$") then
		model = "bcm27xx_bcm2711/rpi-4"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-bcm27xx-bcm2711-rpi-4-squashfs-sysupgrade.img.gz"
    elseif board_name:match("rpi%-3$") then
		model = "bcm27xx_bcm2710/rpi-3"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-bcm27xx-bcm2710-rpi-3-squashfs-sysupgrade.img.gz"
    elseif board_name:match("rpi%-2$") then
		model = "bcm27xx_bcm2709/rpi-2"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-bcm27xx-bcm2709-rpi-2-squashfs-sysupgrade.img.gz"
    elseif board_name:match("rpi$") then
		model = "bcm27xx_bcm2708/rpi"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-bcm27xx-bcm2708-rpi-squashfs-sysupgrade.img.gz"
    elseif board_name:match("redmi%-router%-ax6s$") then
		model = "mediatek_mt7622/xiaomi_redmi-router-ax6s"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-mediatek-mt7622-xiaomi_redmi-router-ax6s-squashfs-sysupgrade.bin"
    elseif board_name:match("redmi,ax6$") then
		model = "ipq807x_generic/redmi_ax6"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ipq807x-generic-redmi_ax6-squashfs-sysupgrade.bin"
    elseif board_name:match("xiaomi,ax9000$") then
		model = "ipq807x_generic/xiaomi_ax9000"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ipq807x-generic-xiaomi_ax9000-squashfs-sysupgrade.bin"
    elseif board_name:match("xiaomi,ax3600$") then
		model = "ipq807x_generic/xiaomi_ax3600"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ipq807x-generic-xiaomi_ax3600-squashfs-sysupgrade.bin"
    elseif board_name:match("xy%-c5$") then
		model = "ramips_mt7621/xiaoyu_xy-c5"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-xiaoyu_xy-c5-squashfs-sysupgrade.bin"
    elseif board_name:match("newifi%-d2$") then
		model = "ramips_mt7621/d-team_newifi-d2"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-d-team_newifi-d2-squashfs-sysupgrade.bin"
    elseif board_name:match("newifi%-d1$") then
		model = "ramips_mt7621/lenovo_newifi-d1"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-lenovo_newifi-d1-squashfs-sysupgrade.bin"
    elseif board_name:match("re%-sp%-01b$") then
		model = "ramips_mt7621/jdcloud_re-sp-01b"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-jdcloud_re-sp-01b-squashfs-sysupgrade.bin"
    elseif board_name:match("mi%-router%-cr660x$") then
		model = "ramips_mt7621/xiaomi_mi-router-cr660x"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-xiaomi_mi-router-cr660x-squashfs-sysupgrade.bin"
    elseif board_name:match("mi%-router%-3%-pro$") then
		model = "ramips_mt7621/xiaomi_mi-router-3-pro"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-xiaomi_mi-router-3-pro-squashfs-sysupgrade.bin"
    elseif board_name:match("mi%-router%-4$") then
		model = "ramips_mt7621/xiaomi_mi-router-4"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-xiaomi_mi-router-4-squashfs-sysupgrade.bin"
    elseif board_name:match("mi%-router%-3g$") then
		model = "ramips_mt7621/xiaomi_mi-router-3g"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-xiaomi_mi-router-3g-squashfs-sysupgrade.bin"
    elseif board_name:match("redmi%-router%-ac2100$") then
		model = "ramips_mt7621/xiaomi_redmi-router-ac2100"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-xiaomi_redmi-router-ac2100-squashfs-sysupgrade.bin"
    elseif board_name:match("mi%-router%-ac2100$") then
		model = "ramips_mt7621/xiaomi_mi-router-ac2100"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-xiaomi_mi-router-ac2100-squashfs-sysupgrade.bin"
    elseif board_name:match("phicomm,k2p$") then
		model = "ramips_mt7621/phicomm_k2p"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-phicomm_k2p-squashfs-sysupgrade.bin"
    elseif board_name:match("phicomm,k2p%-32m$") then
		model = "ramips_mt7621/phicomm_k2p-32m"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-phicomm_k2p-32m-squashfs-sysupgrade.bin"
    elseif board_name:match("phicomm,k3$") then
		model = "bcm53xx_generic/phicomm_k3"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-bcm53xx-generic-phicomm_k3-squashfs.trx"
    elseif board_name:match("hiwifi,hc5962$") then
		model = "ramips_mt7621/hiwifi_hc5962"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-hiwifi_hc5962-squashfs-sysupgrade.bin"
    elseif board_name:match("gl%-mt1300$") then
		model = "ramips_mt7621/glinet_gl-mt1300"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-glinet_gl-mt1300-squashfs-sysupgrade.bin"
    elseif board_name:match("rt%-ac85p$") then
		model = "ramips_mt7621/asus_rt-ac85p"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-asus_rt-ac85p-squashfs-sysupgrade.bin"
    elseif board_name:match("netgear,r6220$") then
		model = "ramips_mt7621/netgear_r6220"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-netgear_r6220-squashfs-sysupgrade.bin"
    elseif board_name:match("netgear,r6260$") then
		model = "ramips_mt7621/netgear_r6260"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-netgear_r6260-squashfs-sysupgrade.bin"
    elseif board_name:match("netgear,r6700%-v2$") then
		model = "ramips_mt7621/netgear_r6700-v2"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-netgear_r6700-v2-squashfs-sysupgrade.bin"
    elseif board_name:match("netgear,r6800$") then
		model = "ramips_mt7621/netgear_r6800"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-netgear_r6800-squashfs-sysupgrade.bin"
    elseif board_name:match("netgear,r6850$") then
		model = "ramips_mt7621/netgear_r6850"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-netgear_r6850-squashfs-sysupgrade.bin"
    elseif board_name:match("netgear,r6900%-v2$") then
		model = "ramips_mt7621/netgear_r6900-v2"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-netgear_r6900-v2-squashfs-sysupgrade.bin"
    elseif board_name:match("netgear,r7450$") then
		model = "ramips_mt7621/netgear_r7450"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-netgear_r7450-squashfs-sysupgrade.bin"
    elseif board_name:match("rt%-n56u%-b1$") then
		model = "ramips_mt7621/asus_rt-n56u-b1"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-asus_rt-n56u-b1-squashfs-sysupgrade.bin"
    elseif board_name:match("timecloud$") then
		model = "ramips_mt7621/thunder_timecloud"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-thunder_timecloud-squashfs-sysupgrade.bin"
    elseif board_name:match("yk%-l2$") then
		model = "ramips_mt7621/youku_yk-l2"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-youku_yk-l2-squashfs-sysupgrade.bin"
    elseif board_name:match("youhua,wr1200js$") then
		model = "ramips_mt7621/youhua_wr1200js"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-youhua_wr1200js-squashfs-sysupgrade.bin"
    elseif board_name:match("oraybox,x3a$") then
		model = "ramramips_mt7621ips/oraybox_x3a"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-oraybox_x3a-squashfs-sysupgrade.bin"
    elseif board_name:match("wndr3700%-v5$") then
		model = "ramips_mt7621/netgear_wndr3700-v5"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-netgear_wndr3700-v5-squashfs-sysupgrade.bin"
    elseif board_name:match("mi%-router%-4a%-gigabit$") then
		model = "ramips_mt7621/xiaomi_mi-router-4a-gigabit"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-xiaomi_mi-router-4a-gigabit-squashfs-sysupgrade.bin"
    elseif board_name:match("mi%-router%-3g%-v2$") then
		model = "ramips_mt7621/xiaomi_mi-router-3g-v2"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-xiaomi_mi-router-3g-v2-squashfs-sysupgrade.bin"
    elseif board_name:match("jcg,y2$") then
		model = "ramips_mt7621/jcg_y2"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-jcg_y2-squashfs-sysupgrade.bin"
    elseif board_name:match("jcg,q20$") then
		model = "ramips_mt7621/jcg_q20"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-jcg_q20-squashfs-sysupgrade.bin"
    elseif board_name:match("edgerouter%-x$") then
		model = "ramips_mt7621/ubnt_edgerouter-x"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-ubnt_edgerouter-x-squashfs-sysupgrade.bin"
    elseif board_name:match("edgerouter%-x%-sfp$") then
		model = "ramips_mt7621/ubnt_edgerouter-x-sfp"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-ubnt_edgerouter-x-sfp-squashfs-sysupgrade.bin"
    elseif board_name:match("msg1500%-x%-00$") then
		model = "ramips_mt7621/raisecom_msg1500-x-00"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-raisecom_msg1500-x-00-squashfs-sysupgrade.bin"
    elseif board_name:match("zte,e8820s$") then
		model = "ramips_mt7621/zte_e8820s"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-zte_e8820s-squashfs-sysupgrade.bin"
    elseif board_name:match("ghl%-r%-001$") then
		model = "ramips_mt7621/gehua_ghl-r-001"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-gehua_ghl-r-001-squashfs-sysupgrade.bin"
    elseif board_name:match("linksys,ea7500%-v2$") then
		model = "ramips_mt7621/linksys_ea7500-v2"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-linksys_ea7500-v2-squashfs-sysupgrade.bin"
    elseif board_name:match("linksys,ea8100%-v1$") then
		model = "ramips_mt7621/linksys_ea8100-v1"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-linksys_ea8100-v1-squashfs-sysupgrade.bin"
    elseif board_name:match("linksys,ea8100%-v2$") then
		model = "ramips_mt7621/linksys_ea8100-v2"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-linksys_ea8100-v2-squashfs-sysupgrade.bin"
    elseif board_name:match("linksys,ea7300%-v1$") then
		model = "ramips_mt7621/linksys_ea7300-v1"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-linksys_ea7300-v1-squashfs-sysupgrade.bin"
    elseif board_name:match("linksys,ea7300%-v2$") then
		model = "ramips_mt7621/linksys_ea7300-v2"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-linksys_ea7300-v2-squashfs-sysupgrade.bin"
    elseif board_name:match("linksys,ea6350%-v4$") then
		model = "ramips_mt7621/linksys_ea6350-v4"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-linksys_ea6350-v4-squashfs-sysupgrade.bin"
    elseif board_name:match("linksys,e5600$") then
		model = "ramips_mt7621/linksys_e5600"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-linksys_e5600-squashfs-sysupgrade.bin"
    elseif board_name:match("jdcloud,luban$") then
		model = "ramips_mt7621/jdcloud_luban"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-jdcloud_luban-squashfs-sysupgrade.bin"
    elseif board_name:match("rt%-ac1200$") then
		model = "ramips_mt76x8/asus_rt-ac1200"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt76x8-asus_rt-ac1200-squashfs-sysupgrade.bin"
    elseif board_name:match("rt%-ac1200%-v2$") then
		model = "ramips_mt76x8/asus_rt-ac1200-v2"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt76x8-asus_rt-ac1200-v2-squashfs-sysupgrade.bin"
    elseif board_name:match("gl%-mt300n%-v2$") then
		model = "ramips_mt76x8/glinet_gl-mt300n-v2"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt76x8-glinet_gl-mt300n-v2-squashfs-sysupgrade.bin"
    elseif board_name:match("microuter%-n300$") then
		model = "ramips_mt76x8/glinet_microuter-n300"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt76x8-glinet_microuter-n300-squashfs-sysupgrade.bin"
    elseif board_name:match("hiwifi,hc5661a$") then
		model = "ramips_mt76x8/hiwifi_hc5661a"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt76x8-hiwifi_hc5661a-squashfs-sysupgrade.bin"
    elseif board_name:match("hiwifi,hc5761a$") then
		model = "ramips_mt76x8/hiwifi_hc5761a"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt76x8-hiwifi_hc5761a-squashfs-sysupgrade.bin"
    elseif board_name:match("hiwifi,hc5861b$") then
		model = "ramips_mt76x8/hiwifi_hc5861b"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt76x8-hiwifi_hc5861b-squashfs-sysupgrade.bin"
    elseif board_name:match("hiwifi,hc5611$") then
		model = "ramips_mt76x8/hiwifi_hc5611"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt76x8-hiwifi_hc5611-squashfs-sysupgrade.bin"
    elseif board_name:match("netgear,r6120$") then
		model = "ramips_mt76x8/netgear_r6120"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt76x8-netgear_r6120-squashfs-sysupgrade.bin"
    elseif board_name:match("miwifi%-nano$") then
		model = "ramips_mt76x8/xiaomi_miwifi-nano"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt76x8-xiaomi_miwifi-nano-squashfs-sysupgrade.bin"
    elseif board_name:match("r619ac%-64m$") then
		model = "ipq40xx_generic/p2w_r619ac-64m"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ipq40xx-generic-p2w_r619ac-64m-squashfs-nand-sysupgrade.bin"
    elseif board_name:match("r619ac%-128m$") then
		model = "ipq40xx_generic/p2w_r619ac-128m"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ipq40xx-generic-p2w_r619ac-128m-squashfs-nand-sysupgrade.bin"
    elseif board_name:match("rt%-ac42u$") then
		model = "ipq40xx_generic/asus_rt-ac42u"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ipq40xx-generic-asus_rt-ac42u-squashfs-sysupgrade.bin"
    elseif board_name:match("rt%-ac58u$") then
		model = "ipq40xx_generic/asus_rt-ac58u"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ipq40xx-generic-asus_rt-ac58u-squashfs-sysupgrade.bin"
    elseif board_name:match("cm520%-79f$") then
		model = "ipq40xx_generic/mobipromo_cm520-79f"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ipq40xx-generic-mobipromo_cm520-79f-squashfs-nand-sysupgrade.bin"
    elseif board_name:match("gl%-a1300$") then
		model = "ipq40xx_generic/glinet_gl-a1300"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ipq40xx-generic-glinet_gl-a1300-squashfs-nand-sysupgrade.bin"
    elseif board_name:match("rt%-ac88u$") then
		model = "bcm53xx_generic/asus_rt-ac88u"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-bcm53xx-generic-asus_rt-ac88u-squashfs.trx"
    elseif board_name:match("linksys,wrt1200ac$") then
		model = "mvebu_cortexa9/linksys_wrt1200ac"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-mvebu-cortexa9-linksys_wrt1200ac-squashfs-sysupgrade.bin"
    elseif board_name:match("linksys,wrt1900ac%-v2$") then
		model = "mvebu_cortexa9/linksys_wrt1900ac-v2"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-mvebu-cortexa9-linksys_wrt1900ac-v2-squashfs-sysupgrade.bin"
    elseif board_name:match("linksys,wrt1900ac%-v1$") then
		model = "mvebu_cortexa9/linksys_wrt1900ac-v1"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-mvebu-cortexa9-linksys_wrt1900ac-v1-squashfs-sysupgrade.bin"
    elseif board_name:match("linksys,wrt3200acm$") then
		model = "mvebu_cortexa9/linksys_wrt3200acm"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-mvebu-cortexa9-linksys_wrt3200acm-squashfs-sysupgrade.bin"
    elseif board_name:match("linksys,wrt1900acs$") then
		model = "mvebu_cortexa9/linksys_wrt1900acs"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-mvebu-cortexa9-linksys_wrt1900acs-squashfs-sysupgrade.bin"
    elseif board_name:match("linksys,wrt32x$") then
		model = "mvebu_cortexa9/linksys_wrt32x"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-mvebu-cortexa9-linksys_wrt32x-squashfs-sysupgrade.bin"
    elseif board_name:match("qihoo,v6$") then
		model = "ipq60xx_generic/qihoo_v6"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ipq60xx-generic-qihoo_v6-squashfs-nand-sysupgrade.bin"
    elseif board_name:match("glinet,axt1800$") then
		model = "ipq807x_ipq60xx/glinet_axt1800"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ipq807x-glinet_axt1800-squashfs-sysupgrade.tar"
    elseif board_name:match("glinet,ax1800$") then
		model = "ipq807x_ipq60xx/glinet_ax1800"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ipq807x-glinet_ax1800-squashfs-sysupgrade.tar"
    elseif board_name:match("linksys,mr7350$") then
		model = "ipq60xx_generic/linksys_mr7350"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ipq60xx-generic-linksys_mr7350-squashfs-nand-sysupgrade.bin"
    elseif board_name:match("cmiot,ax18$") then
		model = "ipq60xx_generic/cmiot_ax18"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ipq60xx-generic-cmiot_ax18-squashfs-nand-sysupgrade.bin"
    elseif board_name:match("zn,m2$") then
		model = "ipq60xx_generic/zn_m2"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ipq60xx-generic-zn_m2-squashfs-nand-sysupgrade.bin"
    elseif board_name:match("xiaomi,rm1800$") then
		model = "ipq60xx_generic/xiaomi_rm1800"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ipq60xx-generic-xiaomi_rm1800-squashfs-nand-sysupgrade.bin"
    elseif board_name:match("wf%-hr6001$") then
		model = "ipq60xx_generic/huasifei_wf-hr6001"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ipq60xx-generic-huasifei_wf-hr6001-squashfs-nand-sysupgrade.bin"
    elseif board_name:match("gl%-mt300a$") then
		model = "ramips_mt7620/glinet_gl-mt300a"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7620-glinet_gl-mt300a-squashfs-sysupgrade.bin"
    elseif board_name:match("gl%-mt750$") then
		model = "ramips_mt7620/glinet_gl-mt750"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7620-glinet_gl-mt750-squashfs-sysupgrade.bin"
    elseif board_name:match("hiwifi,hc5661$") then
		model = "ramips_mt7620/hiwifi_hc5661"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7620-hiwifi_hc5661-squashfs-sysupgrade.bin"
    elseif board_name:match("hiwifi,hc5761$") then
		model = "ramips_mt7620/hiwifi_hc5761"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7620-hiwifi_hc5761-squashfs-sysupgrade.bin"
    elseif board_name:match("hiwifi,hc5861$") then
		model = "ramips_mt7620/hiwifi_hc5861"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7620-hiwifi_hc5861-squashfs-sysupgrade.bin"
    elseif board_name:match("newifi%-y1$") then
		model = "ramips_mt7620/lenovo_newifi-y1"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7620-lenovo_newifi-y1-squashfs-sysupgrade.bin"
    elseif board_name:match("newifi%-y1s$") then
		model = "ramips_mt7620/lenovo_newifi-y1s"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7620-lenovo_newifi-y1s-squashfs-sysupgrade.bin"
    elseif board_name:match("miwifi%-mini$") then
		model = "ramips_mt7620/xiaomi_miwifi-mini"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7620-xiaomi_miwifi-mini-squashfs-sysupgrade.bin"
    elseif board_name:match("yk%-l1$") then
		model = "ramips_mt7620/youku_yk-l1"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7620-youku_yk-l1-squashfs-sysupgrade.bin"
    elseif board_name:match("yk%-l1c$") then
		model = "ramips_mt7620/youku_yk-l1c"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7620-youku_yk-l1c-squashfs-sysupgrade.bin"
    elseif board_name:match("miwifi%-r3$") then
		model = "ramips_mt7620/xiaomi_miwifi-r3"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7620-xiaomi_miwifi-r3-squashfs-sysupgrade.bin"
    elseif board_name:match("hiwifi,r33$") then
		model = "ramips_mt7620/hiwifi_r33"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7620-hiwifi_r33-squashfs-sysupgrade.bin"
    elseif board_name:match("redmi%-router%-ax6000$") then
		model = "mediatek_mt7986/xiaomi_redmi-router-ax6000"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-mediatek-mt7986-xiaomi_redmi-router-ax6000-squashfs-sysupgrade.bin"
    elseif board_name:match("mt7981%-360%-t7%-108M$") then
		model = "mediatek_mt7981/mt7981-360-t7-108M"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-mediatek-mt7981-mt7981-360-t7-108M-squashfs-sysupgrade.bin"
    elseif board_name:match("linksys,ea4500$") then
		model = "kirkwood_generic/linksys_ea4500"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-kirkwood-linksys_ea4500-squashfs-sysupgrade.bin"
    elseif board_name:match("linksys,e4200%-v2$") then
		model = "kirkwood_generic/linksys_e4200-v2"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-kirkwood-linksys_e4200-v2-squashfs-sysupgrade.bin"
    elseif board_name:match("thunder%-onecloud$") then
		model = "meson_meson8/thunder-onecloud"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-meson-meson8b-thunder-onecloud-ext4-sdcard.img.gz"
    elseif board_name:match("gl%-ar300m%-nand$") then
		model = "ath79_nand/glinet_gl-ar300m-nand"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ath79-nand-glinet_gl-ar300m-nand-squashfs-sysupgrade.bin"
    elseif board_name:match("gl%-ar750s%-nor%-nand$") then
		model = "ath79_nand/glinet_gl-ar750s-nor-nand"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ath79-nand-glinet_gl-ar750s-nor-nand-squashfs-sysupgrade.bin"
    elseif board_name:match("gl%-e750$") then
		model = "ath79_nand/glinet_gl-e750"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ath79-nand-glinet_gl-e750-squashfs-sysupgrade.bin"
    elseif board_name:match("gl%-xe300$") then
		model = "ath79_nand/glinet_gl-xe300"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ath79-nand-glinet_gl-xe300-squashfs-sysupgrade.bin"
    elseif board_name:match("netgear,r6100$") then
		model = "ath79_nand/netgear_r6100"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ath79-nand-netgear_r6100-squashfs-sysupgrade.bin"
    elseif board_name:match("wndr3700%-v4$") then
		model = "ath79_nand/netgear_wndr3700-v4"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ath79-nand-netgear_wndr3700-v4-squashfs-sysupgrade.bin"
    elseif board_name:match("netgear,wndr4300$") then
		model = "ath79_nand/netgear_wndr4300"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ath79-nand-netgear_wndr4300-squashfs-sysupgrade.bin"
    elseif board_name:match("wndr4300%-v2$") then
		model = "ath79_nand/netgear_wndr4300-v2"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ath79-nand-netgear_wndr4300-v2-squashfs-sysupgrade.bin"
    elseif board_name:match("netgear,wndr4300sw$") then
		model = "ath79_nand/netgear_wndr4300sw"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ath79-nand-netgear_wndr4300sw-squashfs-sysupgrade.bin"
    elseif board_name:match("netgear,wndr4300tn$") then
		model = "ath79_nand/netgear_wndr4300tn"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ath79-nand-netgear_wndr4300tn-squashfs-sysupgrade.bin"
    elseif board_name:match("wndr4500%-v3$") then
		model = "ath79_nand/netgear_wndr4500-v3"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ath79-nand-netgear_wndr4500-v3-squashfs-sysupgrade.bin"
    elseif board_name:match("zte,mf286$") then
		model = "ath79_nand/zte_mf286"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ath79-nand-zte_mf286-squashfs-sysupgrade.bin"
    elseif board_name:match("gl%-mt2500$") then
		model = "mt7981/glinet_gl-mt2500"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-mediatek_gl-mt7981-glinet_gl-mt2500-squashfs-sysupgrade.bin"
    elseif board_name:match("gl%-mt3000$") then
		model = "mt7981/glinet_gl-mt3000"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-mediatek_gl-mt7981-glinet_gl-mt3000-squashfs-sysupgrade.bin"
    elseif board_name:match("gl%-x3000$") then
		model = "mt7981/glinet_gl-x3000"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-mediatek_gl-mt7981-glinet_gl-x3000-squashfs-sysupgrade.bin"
    elseif board_name:match("gl%-xe3000$") then
		model = "mt7981/glinet_gl-xe3000"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-mediatek_gl-mt7981-glinet_gl-xe3000-squashfs-sysupgrade.bin"
    else
		local needs_update = false
		return {
            code = 1,
            error = i18n.translate("Can't determine MODEL, or MODEL not supported.")
			}
    end
	

    if needs_update and not download_url then
        return {
            code = 1,
            now_version = get_system_version(),
            version = remote_version,
            error = i18n.translate(
                "New version found, but failed to get new version download url.")
        }
    end

    return {
        code = 0,
        update = needs_update,
        notice = notice,
        now_version = get_system_version(),
        version = remote_version,
        md5 = md5,
        logs = updatelogs,
        url = download_url
    }
end

function to_download(url,md5)
    if not url or url == "" then
        return {code = 1, error = i18n.translate("Download url is required.")}
    end

    sys.call("/bin/rm -f /tmp/firmware_download.*")

    local tmp_file = util.trim(util.exec("mktemp -u -t firmware_download.XXXXXX"))

    local result = api.exec(api.wget, {api._unpack(api.wget_args), "-O", tmp_file, url}, nil, api.command_timeout) == 0

    if not result then
        api.exec("/bin/rm", {"-f", tmp_file})
        return {
            code = 1,
            error = i18n.translatef("File download failed or timed out: %s", url)
        }
    end

	local md5local = sys.exec("echo -n $(md5sum " .. tmp_file .. " | awk '{print $1}')")

	if md5 ~= "" and md5local ~= md5 then
		api.exec("/bin/rm", {"-f", tmp_file})
		return {
            code = 1,
            error = i18n.translatef("Md5 check failed: %s", url)
        }
	end

    return {code = 0, file = tmp_file}
end

function to_flash(file,retain)
    if not file or file == "" or not fs.access(file) then
        return {code = 1, error = i18n.translate("Firmware file is required.")}
    end
    sys.call("/sbin/sysupgrade " ..retain.. " " ..file.. "")

    return {code = 0}
end
