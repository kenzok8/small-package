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
    elseif board_name:match(".*nanopi-r2s") then
		model = "rockchip_armv8/friendlyarm_nanopi-r2s"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-rockchip-armv8-friendlyarm_nanopi-r2s-squashfs-sysupgrade.img.gz"
    elseif board_name:match(".*nanopi-r4s") then
		model = "rockchip_armv8/friendlyarm_nanopi-r4s"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-rockchip-armv8-friendlyarm_nanopi-r4s-squashfs-sysupgrade.img.gz"
    elseif board_name:match(".*nanopi-r5s") then
		model = "rockchip_armv8/friendlyarm_nanopi-r5s"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-rockchip-armv8-friendlyarm_nanopi-r5s_sd.img.gz"
    elseif board_name:match(".*nanopi-r2c") then
		model = "rockchip_armv8/friendlyarm_nanopi-r2c"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-rockchip-armv8-friendlyarm_nanopi-r2c-squashfs-sysupgrade.img.gz"
    elseif board_name:match(".*doornet2") then
		model = "rockchip_armv8/embedfire_doornet2"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-rockchip-armv8-embedfire_doornet2-squashfs-sysupgrade.img.gz"
    elseif board_name:match(".*doornet1") then
		model = "rockchip_armv8/embedfire_doornet1"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-rockchip-armv8-embedfire_doornet1-squashfs-sysupgrade.img.gz"
    elseif board_name:match(".*r1-plus-lts") then
		model = "rockchip_armv8/xunlong_orangepi-r1-plus-lts"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-rockchip-armv8-xunlong_orangepi-r1-plus-lts-squashfs-sysupgrade.img.gz"
    elseif board_name:match(".*r1-plus") then
		model = "rockchip_armv8/xunlong_orangepi-r1-plus"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-rockchip-armv8-xunlong_orangepi-r1-plus-squashfs-sysupgrade.img.gz"
    elseif board_name:match(".*_nanopi-neo3.*") then
		model = "rockchip_armv8/friendlyarm_nanopi-neo3"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-rockchip-armv8-nanopi-neo3-squashfs-sysupgrade.img.gz"
    elseif board_name:match(".*rpi-4") then
		model = "bcm27xx_bcm2711/rpi-4"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-bcm27xx-bcm2711-rpi-4-squashfs-sysupgrade.img.gz"
    elseif board_name:match(".*rpi-3") then
		model = "bcm27xx_bcm2710/rpi-3"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-bcm27xx-bcm2710-rpi-3-squashfs-sysupgrade.img.gz"
    elseif board_name:match(".*rpi-2") then
		model = "bcm27xx_bcm2709/rpi-2"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-bcm27xx-bcm2709-rpi-2-squashfs-sysupgrade.img.gz"
    elseif board_name:match(".*redmi-router_ax6s") then
		model = "mediatek_mt7622/xiaomi_redmi-router_ax6s"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-mediatek-mt7622-xiaomi_redmi-router-ax6s-squashfs-sysupgrade.bin"
    elseif board_name:match(".*redmi_ax6") then
		model = "ipq807x_generic/redmi_ax6"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ipq807x-generic-redmi_ax6-squashfs-nand-sysupgrade.bin"
    elseif board_name:match(".*xiaomi_ax9000") then
		model = "ipq807x_generic/xiaomi_ax9000"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ipq807x-generic-xiaomi_ax9000-squashfs-nand-sysupgrade.bin"
    elseif board_name:match(".*xiaomi_ax3600") then
		model = "ipq807x_generic/xiaomi_ax3600"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ipq807x-generic-xiaomi_ax3600-squashfs-nand-sysupgrade.bin"
    elseif board_name:match(".*xy-c5") then
		model = "ramips_mt7621/xiaoyu_xy-c5"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-xiaoyu_xy-c5-squashfs-sysupgrade.bin"
    elseif board_name:match(".*newifi-d2") then
		model = "ramips_mt7621/d-team_newifi-d2"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-d-team_newifi-d2-squashfs-sysupgrade.bin"
    elseif board_name:match(".*mi-router-cr660x") then
		model = "ramips_mt7621/xiaomi_mi-router-cr660x"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-xiaomi_mi-router-cr660x-squashfs-sysupgrade.bin"
    elseif board_name:match(".*mi-router-3-pro") then
		model = "ramips_mt7621/xiaomi_mi-router-3-pro"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-xiaomi_mi-router-3-pro-squashfs-sysupgrade.bin"
    elseif board_name:match(".*mi-router-4") then
		model = "ramips_mt7621/xiaomi_mi-router-4"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-xiaomi_mi-router-4-squashfs-sysupgrade.bin"
    elseif board_name:match(".*mi-router-3g") then
		model = "ramips_mt7621/xiaomi_mi-router-3g"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-xiaomi_mi-router-3g-squashfs-sysupgrade.bin"
    elseif board_name:match(".*redmi-router-ac2100") then
		model = "ramips_mt7621/xiaomi_redmi-router-ac2100"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-xiaomi_redmi-router-ac2100-squashfs-sysupgrade.bin"
    elseif board_name:match(".*mi-router-ac2100") then
		model = "ramips_mt7621/xiaomi_mi-router-ac2100"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-xiaomi_mi-router-ac2100-squashfs-sysupgrade.bin"
    elseif board_name:match(".*rt-acrh17") then
		model = "ipq40xx_generic/asus_rt-acrh17"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ipq40xx-generic-asus_rt-ac42u-squashfs-sysupgrade.bin"
    elseif board_name:match(".*rt-ac58u") then
		model = "ipq40xx_generic/asus_rt-ac58u"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ipq40xx-generic-asus_rt-ac58u-squashfs-sysupgrade.bin"
    elseif board_name:match("phicomm,k2p") then
		model = "ramips_mt7621/phicomm_k2p"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-phicomm_k2p-squashfs-sysupgrade.bin"
    elseif board_name:match("phicomm,k3") then
		model = "bcm53xx_generic/phicomm_k3"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-bcm53xx-generic-phicomm_k3-squashfs.trx"
    elseif board_name:match(".*hc5962") then
		model = "ramips_mt7621/hiwifi_hc5962"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-hiwifi_hc5962-squashfs-sysupgrade.bin"
    elseif board_name:match(".*gl-mt1300") then
		model = "ramips_mt7621/glinet_gl-mt1300"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-glinet_gl-mt1300-squashfs-sysupgrade.bin"
    elseif board_name:match(".*rt-ac85p") then
		model = "ramips_mt7621/asus_rt-ac85p"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-asus_rt-ac85p-squashfs-sysupgrade.bin"
    elseif board_name:match(".*r6220") then
		model = "ramips_mt7621/netgear_r6220"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-netgear_r6220-squashfs-sysupgrade.bin"
    elseif board_name:match(".*r6260") then
		model = "ramips_mt7621/netgear_r6260"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-netgear_r6260-squashfs-sysupgrade.bin"
    elseif board_name:match(".*r6700-v2") then
		model = "ramips_mt7621/netgear_r6700-v2"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-netgear_r6700-v2-squashfs-sysupgrade.bin"
    elseif board_name:match(".*r6800") then
		model = "ramips_mt7621/netgear_r6800"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-netgear_r6800-squashfs-sysupgrade.bin"
    elseif board_name:match(".*r6850") then
		model = "ramips_mt7621/netgear_r6850"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-netgear_r6850-squashfs-sysupgrade.bin"
    elseif board_name:match(".*r6900-v2") then
		model = "ramips_mt7621/netgear_r6900-v2"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-netgear_r6900-v2-squashfs-sysupgrade.bin"
    elseif board_name:match(".*r7450") then
		model = "ramips_mt7621/netgear_r7450"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-netgear_r7450-squashfs-sysupgrade.bin"
    elseif board_name:match(".*rt-n56u-b1") then
		model = "ramips_mt7621/asus_rt-n56u-b1"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-asus_rt-n56u-b1-squashfs-sysupgrade.bin"
    elseif board_name:match(".*timecloud") then
		model = "ramips_mt7621/thunder_timecloud"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-thunder_timecloud-squashfs-sysupgrade.bin"
    elseif board_name:match(".*yk-l2") then
		model = "ramips_mt7621/youku_yk-l2"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-youku_yk-l2-squashfs-sysupgrade.bin"
    elseif board_name:match(".*wr1200js") then
		model = "ramips_mt7621/youhua_wr1200js"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-youhua_wr1200js-squashfs-sysupgrade.bin"
    elseif board_name:match(".*x3a") then
		model = "ramramips_mt7621ips/oraybox_x3a"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-oraybox_x3a-squashfs-sysupgrade.bin"
    elseif board_name:match(".*wndr3700-v5") then
		model = "ramips_mt7621/netgear_wndr3700-v5"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-netgear_wndr3700-v5-squashfs-sysupgrade.bin"
    elseif board_name:match(".*mi-router-4a-gigabit") then
		model = "ramips_mt7621/xiaomi_mi-router-4a-gigabit"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-xiaomi_mi-router-4a-gigabit-squashfs-sysupgrade.bin"
    elseif board_name:match(".*mi-router-3g-v2") then
		model = "ramips_mt7621/xiaomi_mi-router-3g-v2"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-xiaomi_mi-router-3g-v2-squashfs-sysupgrade.bin"
    elseif board_name:match(".*rt-ac1200") then
		model = "ramips_mt76x8/asus_rt-ac1200"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt76x8-asus_rt-ac1200-squashfs-sysupgrade.bin"
    elseif board_name:match(".*rt-ac1200-v2") then
		model = "ramips_mt76x8/asus_rt-ac1200-v2"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt76x8-asus_rt-ac1200-v2-squashfs-sysupgrade.bin"
    elseif board_name:match(".*gl-mt300n-v2") then
		model = "ramips_mt76x8/glinet_gl-mt300n-v2"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt76x8-glinet_gl-mt300n-v2-squashfs-sysupgrade.bin"
    elseif board_name:match(".*microuter-n300") then
		model = "ramips_mt76x8/glinet_microuter-n300"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt76x8-glinet_microuter-n300-squashfs-sysupgrade.bin"
    elseif board_name:match(".*hc5661a") then
		model = "ramips_mt76x8/hiwifi_hc5661a"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt76x8-hiwifi_hc5661a-squashfs-sysupgrade.bin"
    elseif board_name:match(".*hc5761a") then
		model = "ramips_mt76x8/hiwifi_hc5761a"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt76x8-hiwifi_hc5761a-squashfs-sysupgrade.bin"
    elseif board_name:match(".*hc5861b") then
		model = "ramips_mt76x8/hiwifi_hc5861b"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt76x8-hiwifi_hc5861b-squashfs-sysupgrade.bin"
    elseif board_name:match(".*r6120") then
		model = "ramips_mt76x8/netgear_r6120"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt76x8-netgear_r6120-squashfs-sysupgrade.bin"
    elseif board_name:match(".*miwifi-nano") then
		model = "ramips_mt76x8/xiaomi_miwifi-nano"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt76x8-xiaomi_miwifi-nano-squashfs-sysupgrade.bin"
    elseif board_name:match(".*r619ac-64m") then
		model = "ipq40xx_generic/p2w_r619ac-64m"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ipq40xx-generic-p2w_r619ac-64m-squashfs-sysupgrade.bin"
    elseif board_name:match(".*r619ac-128m") then
		model = "ipq40xx_generic/p2w_r619ac-128m"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ipq40xx-generic-p2w_r619ac-128m-squashfs-sysupgrade.bin"
    elseif board_name:match(".*rt-ac88u") then
		model = "bcm53xx_generic/asus_rt-ac88u"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-bcm53xx-generic-asus_rt-ac88u-squashfs.trx"
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
    sys.call(". /etc/profile.d/opkg.sh;opkg save;/sbin/sysupgrade " ..retain.. " " ..file.. "")

    return {code = 0}
end
