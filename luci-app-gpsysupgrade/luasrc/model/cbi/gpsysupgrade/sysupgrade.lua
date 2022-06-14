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
    if not model or model == "" then model = api.auto_get_model() end
	sysverformat = luci.sys.exec("date -d $(echo " ..get_system_version().. " | awk -F. '{printf $3\"-\"$1\"-\"$2}') +%s")
	currentTimeStamp = luci.sys.exec("expr $(date -d \"$(date '+%Y-%m-%d %H:%M:%S')\" +%s) - 172800")
	if model == "x86_64" then
		check_update()
		if fs.access("/sys/firmware/efi") then
			download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-x86-64-generic-squashfs-combined-efi.img.gz"
		else
			download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-x86-64-generic-squashfs-combined.img.gz"
			md5 = ""
		end
    elseif model:match(".*R2S.*") then
		model = "rockchip_armv8/nanopi-r2s"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-rockchip-armv8-nanopi-r2s-squashfs-sysupgrade.img.gz"
    elseif model:match(".*R4S.*") then
		model = "rockchip_armv8/nanopi-r4s"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-rockchip-armv8-nanopi-r4s-squashfs-sysupgrade.img.gz"
    elseif model:match(".*R5S.*") then
		model = "rockchip_armv8/nanopi-r5s"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-rockchip-armv8-nanopi-r5s_sd.img.gz"
    elseif model:match(".*R2C.*") then
		model = "rockchip_armv8/nanopi-r2c"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-rockchip-armv8-nanopi-r2c-squashfs-sysupgrade.img.gz"
    elseif model:match(".*DoorNet2.*") then
		model = "rockchip_armv8/doornet2"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-rockchip-armv8-embedfire_doornet2-squashfs-sysupgrade.img.gz"
    elseif model:match(".*DoorNet1.*") then
		model = "rockchip_armv8/doornet1"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-rockchip-armv8-embedfire_doornet1-squashfs-sysupgrade.img.gz"
    elseif model:match(".*R1 Plus LTS.*") then
		model = "rockchip_armv8/r1-plus-lts"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-rockchip-armv8-xunlong_orangepi-r1-plus-lts-squashfs-sysupgrade.img.gz"
    elseif model:match(".*R1 Plus.*") then
		model = "rockchip_armv8/r1-plus"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-rockchip-armv8-xunlong_orangepi-r1-plus-squashfs-sysupgrade.img.gz"
    elseif model:match(".*NEO3.*") then
		model = "rockchip_armv8/nanopi-neo3"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-rockchip-armv8-nanopi-neo3-squashfs-sysupgrade.img.gz"
    elseif model:match(".*Pi 4 Model B.*") then
		model = "bcm27xx_bcm2711/Rpi-4B"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-bcm27xx-bcm2711-rpi-4-squashfs-sysupgrade.img.gz"
    elseif model:match(".*AX6S.*") then
		model = "mediatek_mt7622/redmi-ax6s"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-mediatek-mt7622-redmi-ax6s-squashfs-sysupgrade.bin"
    elseif model:match(".*AX6.*") then
		model = "ipq807x/redmi-ax6"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ipq807x-generic-redmi_ax6-squashfs-nand-sysupgrade.bin"
    elseif model:match(".*AX9000.*") then
		model = "ipq807x/xiaomi-ax9000"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ipq807x-generic-xiaomi_ax9000-squashfs-nand-sysupgrade.bin"
    elseif model:match(".*AX3600.*") then
		model = "ipq807x/xiaomi-ax3600"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ipq807x-generic-xiaomi_ax3600-squashfs-nand-sysupgrade.bin"
    elseif model:match(".*XY-C5.*") then
		model = "ramips_mt7621/xy-c5"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-xiaoyu_xy-c5-squashfs-sysupgrade.bin"
    elseif model:match(".*D2") then
		model = "ramips_mt7621/newifi-d2"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-d-team_newifi-d2-squashfs-sysupgrade.bin"
    elseif model:match(".*CR660x.*") then
		model = "ramips_mt7621/cr660x"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-xiaomi_mi-router-cr660x-squashfs-sysupgrade.bin"
    elseif model:match("Mi Router 3 Pro") then
		model = "ramips_mt7621/xiaomi-3pro"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-xiaomi_mi-router-3-pro-squashfs-sysupgrade.bin"
    elseif model:match("Mi Router 4") then
		model = "ramips_mt7621/xiaomi-4"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-xiaomi_mi-router-4-squashfs-sysupgrade.bin"
    elseif model:match("Mi Router 3G") then
		model = "ramips_mt7621/xiaomi-3g"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-xiaomi_mi-router-3g-squashfs-sysupgrade.bin"
    elseif model:match(".*Redmi Router AC2100.*") then
		model = "ramips_mt7621/redmi-ac2100"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-redmi-ac2100-squashfs-sysupgrade.bin"
    elseif model:match(".*Mi Router AC2100.*") then
		model = "ramips_mt7621/mi-ac2100"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-ramips-mt7621-xiaomi_mi-ac2100-squashfs-sysupgrade.bin"
    elseif model:match(".*RT-AC42U.*") then
		model = "ipq40xx_generic/asus-rt-acrh17"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-asus_rt-ac42u-squashfs-sysupgrade.bin"
    elseif model:match(".*RT-AC58U.*") then
		model = "ipq40xx_generic/asus-rt-ac58u"
		check_update()
		download_url = "https://op.supes.top/firmware/" ..model.. "/" ..remote_version.. "-openwrt-asus_rt-ac58u-squashfs-sysupgrade.bin"
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
