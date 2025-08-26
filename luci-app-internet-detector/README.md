# Internet detector for OpenWrt.
Internet-detector is an application for checking the availability of the Internet. Performs periodic connections to a known public host and determines the actual Internet availability.

**Features:**
 - It can run continuously as a system service or only in an open web interface.
 - Checking the availability of a host using ping or by connecting via TCP to a specified port.
 - LED indication of Internet availability.
![](https://github.com/gSpotx2f/luci-app-internet-detector/blob/master/screenshots/internet-led.jpg)
 - Performing actions when connecting and disconnecting the Internet: rebooting device, restarting network or modem (internet-detector-mod-modem-restart), executing custom shell scripts.
 - Sending email notification when Internet access is restored (internet-detector-mod-email).
 - Sending telegtam notification when Internet access is restored (internet-detector-mod-telegram).
 - The daemon is written entirely in Lua using the luaposix library.

**OpenWrt >= 21.02.**

**Dependences:** lua, luaposix, libuci-lua.

**Recommended:** curl.

## Installation notes:

    opkg update
    wget --no-check-certificate -O /tmp/internet-detector_1.6.3-r1_all.ipk https://github.com/gSpotx2f/packages-openwrt/raw/master/current/internet-detector_1.6.3-r1_all.ipk
    opkg install /tmp/internet-detector_1.6.3-r1_all.ipk
    rm /tmp/internet-detector_1.6.3-r1_all.ipk
    service internet-detector start
    service internet-detector enable

    wget --no-check-certificate -O /tmp/luci-app-internet-detector_1.6.3-r1_all.ipk https://github.com/gSpotx2f/packages-openwrt/raw/master/current/luci-app-internet-detector_1.6.3-r1_all.ipk
    opkg install /tmp/luci-app-internet-detector_1.6.3-r1_all.ipk
    rm /tmp/luci-app-internet-detector_1.6.3-r1_all.ipk
    service rpcd restart

i18n-ru:

    wget --no-check-certificate -O /tmp/luci-i18n-internet-detector-ru_1.6.3-r1_all.ipk https://github.com/gSpotx2f/packages-openwrt/raw/master/current/luci-i18n-internet-detector-ru_1.6.3-r1_all.ipk
    opkg install /tmp/luci-i18n-internet-detector-ru_1.6.3-r1_all.ipk
    rm /tmp/luci-i18n-internet-detector-ru_1.6.3-r1_all.ipk

## Screenshots:

![](https://github.com/gSpotx2f/luci-app-internet-detector/blob/master/screenshots/01.jpg)
![](https://github.com/gSpotx2f/luci-app-internet-detector/blob/master/screenshots/02.jpg)
![](https://github.com/gSpotx2f/luci-app-internet-detector/blob/master/screenshots/03.jpg)

## Modem restart module (internet-detector-mod-modem-restart):

**Dependences:** modemmanager.

    wget --no-check-certificate -O /tmp/internet-detector-mod-modem-restart_1.6.3-r1_all.ipk https://github.com/gSpotx2f/packages-openwrt/raw/master/current/internet-detector-mod-modem-restart_1.6.3-r1_all.ipk
    opkg install /tmp/internet-detector-mod-modem-restart_1.6.3-r1_all.ipk
    rm /tmp/internet-detector-mod-modem-restart_1.6.3-r1_all.ipk
    service internet-detector restart

![](https://github.com/gSpotx2f/luci-app-internet-detector/blob/master/screenshots/04.jpg)

## Email notification module (internet-detector-mod-email):

**Dependences:** mailsend.

    wget --no-check-certificate -O /tmp/internet-detector-mod-email_1.6.3-r1_all.ipk https://github.com/gSpotx2f/packages-openwrt/raw/master/current/internet-detector-mod-email_1.6.3-r1_all.ipk
    opkg install /tmp/internet-detector-mod-email_1.6.3-r1_all.ipk
    rm /tmp/internet-detector-mod-email_1.6.3-r1_all.ipk
    service internet-detector restart

![](https://github.com/gSpotx2f/luci-app-internet-detector/blob/master/screenshots/05.jpg)

## Telegram notification module (internet-detector-mod-telegram):

**Dependences:** curl.

    wget --no-check-certificate -O /tmp/internet-detector-mod-telegram_1.6.3-r1_all.ipk https://github.com/gSpotx2f/packages-openwrt/raw/master/current/internet-detector-mod-telegram_1.6.3-r1_all.ipk
    opkg install /tmp/internet-detector-mod-telegram_1.6.3-r1_all.ipk
    rm /tmp/internet-detector-mod-telegram_1.6.3-r1_all.ipk
    service internet-detector restart

![](https://github.com/gSpotx2f/luci-app-internet-detector/blob/master/screenshots/06.jpg)
