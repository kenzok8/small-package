# luci-app-xray

[luci-app-v2ray](https://github.com/yichya/luci-app-v2ray) refined to client side rendering (and switched to xray as well).

Focus on making the most of Xray (HTTP/HTTPS/Socks/TProxy inbounds, multiple protocols support, DNS server, bridge (reverse proxy), even HTTPS proxy server for actual HTTP services) while keeping thin and elegant.

## Warnings

* Support for nftables / firewall4 is **experimental** and
    * only works with OpenWrt 22.03 versions or master branch with firewall4 as the only firewall implementation
    * may **NOT** be as stable as the old implementation using iptables and fw3 due to the lack of hooking facilities in fw4. However it should be good enough for daily use so if you encounter problems please report.
    * currently only tested with a proper buildroot environment. Building ipk with OpenWrt SDK is **NOT** tested and is **NOT** likely to work right now. If you are building ipks yourself, use the proper version of buildroot toolchain which matches the firewall implementation (fw3 or fw4) you are using.
* There will be a series of **BREAKING CHANGES** in the following months due to some major refactor of DNS module. Please read changelog carefully to know about breaking changes and always backup your configuration files before updating.
* If you see `WARNING: at least one of asset files (geoip.dat, geosite.dat) is not found under /usr/share/xray. Xray may not work properly` and don't know what to do:
    * try `opkg update && opkg install xray-geodata` (at least OpenWrt 21.02 releases)
    * if that doesn't work or you are using OpenWrt 19.07 releases, see [#52](https://github.com/yichya/luci-app-xray/issues/52#issuecomment-856059905)
* This project **DOES NOT SUPPORT** the following versions of OpenWrt due to the fact that client side rendering requires LuCI client side APIs shipped with at least OpenWrt 19.07 releases. 
    * LEDE 17.01
    * OpenWrt 18.06
    * [Lean's OpenWrt Source](https://github.com/coolsnowwolf/lede) (which uses a variant of LuCI shipped with OpenWrt 18.06)

    If this is your case, use Passwall or similar projects instead (you could find links in [XTLS/Xray-core](https://github.com/XTLS/Xray-core/)).
* For OpenWrt 19.07 releases, you need to prepare your own xray-core package (just download from [Releases · yichya/openwrt-xray](https://github.com/yichya/openwrt-xray/releases) and install that) because building Xray from source requires Go 1.17 which is currently only available in at least OpenWrt 21.02 releases.
* This project may change its code structure, configuration files format, user interface or dependencies quite frequently since it is still in its very early stage. 

## Changelog 2022

* 2022-01-08 feat: bridge; add DomainStrategy for outbound; minor UI changes
* 2022-01-31 fix: multiple hosts in lan access control; simplify init script
* 2022-02-01 feat: refactor transparent-proxy-ipset to use lua
* 2022-02-02 feat: return certain domain names as NXDOMAIN
* 2022-02-03 fix: failed to start Xray when blocked domain list is empty
* 2022-02-15 feat: add a large `rlimit_data` option
* 2022-02-19 fix: `rlimit_data` and `rlimit_nofile` does not work together
* 2022-02-20 fix: return a discarded address instead of nxdomain to let dnsmasq cache these queries
* 2022-03-25 feat: remove web and add metrics configurations (recommended to use with [metrics support](https://github.com/XTLS/Xray-core/pull/1000))
* 2022-04-24 feat: metrics is now out of optional features; add basic ubus wrapper for xray apis
* 2022-05-13 feat: shadowsocks-2022 protocols support
* 2022-06-04 feat: nftables support (experimental)

## Changelog 2021

* 2021-01-01 feature: build Xray from source; various fixes about tproxy and logging
* 2021-01-25 feature: Xray act as HTTPS server
* 2021-01-29 fix: add ipset as dependency to fix transparent proxy problems; remove useless and faulty extra_command in init.d script
* 2021-01-29 feature: decouple with Xray original binary and data files. Use [openwrt-xray](https://github.com/yichya/openwrt-xray) instead.
* 2021-01-30 feature: select GeoIP set for direct connection. This is considered a **BREAKING** change because if unspecified, all IP addresses is forwarded through Xray.
* 2021-03-17 feature: support custom configuration files by using Xray integrated [Multiple configuration files support](https://xtls.github.io/config/features/multiple.html). Check `/var/etc/xray/config.json` for tags of generated inbounds and outbounds.
* 2021-03-20 fix: no longer be compatible with [OpenWrt Packages: xray-core](https://github.com/openwrt/packages/tree/master/net/xray-core) because of naming conflict of configuration file and init script. Again, use
[openwrt-xray](https://github.com/yichya/openwrt-xray) instead.
* 2021-03-21 feature: detailed fallback config for Xray HTTPS server
* 2021-03-27 feature: check data files before using them. If data files don't exist, Xray will run in 'full' mode (all outgoing network traffic will be forwarded through Xray). Make sure you have a working server in this case or you have to disable Xray temporarily (SSH into your router and run `service xray stop`) for debugging. You can download data files from [Releases · XTLS/Xray-core](https://github.com/XTLS/xray-core/releases) or [Loyalsoldier/v2ray-rules-dat](https://github.com/Loyalsoldier/v2ray-rules-dat) and upload them to `/usr/share/xray` on your router, or just compile your firmware with data files included (recommended in most cases).
* 2021-04-02 feature: utls fingerprint (currently not available for xtls and [will be supported in Xray-core v1.5.0](https://github.com/XTLS/Xray-core/pull/451))
* 2021-04-06 feature: customize DNS bypass rules. This is considered a **BREAKING** change because if unspecified, all DNS requests is forwarded through Xray.
* 2021-05-15 feature: add gRPC Transport settings; make init script infinite retry optional
* 2021-07-03 fix: write upstream hostname to dnsmasq configurations to avoid infinite loop while resolving upstream hostname
* 2021-08-31 feature: Accept more DNS server formats
* 2021-09-19 fix: compatible with latest dnsmasq (2.86) by adding `strict-order` to dnsmasq options generated by luci-app-xray. This should not affect compatibility with earlier dnsmasq versions (mostly 2.85) but if you encounter problems please report.
* 2021-09-26 fix: several issues related to HTTPS server
* 2021-10-01 fix: parsing default gateway in some cases
* 2021-10-06 feature: show information about asset files in LuCI; fix Xray startup when asset files are unavailable
* 2021-10-08 feature: extra DNS Server Port to reduce possibility of temporary DNS lookup failures
* 2021-10-09 fix: temporarily revert DNS over HTTPS related changes to avoid dnsmasq and iptables errors
* 2021-10-12 fix: domain based routing if sniffing is enabled
* 2021-10-19 feat: change upstream DNS resolve method to directly using Xray internal DNS server
* 2021-11-14 feat: LAN access control for transparent proxy. Devices can be set to not being transparently proxied per MAC address.
* 2021-11-15 feat: manual transparent proxy. A use case is accessing IPv6 only websites without any IPv6 address (for example, `192.0.2.1:443 -> tracker.byr.pt:443` and add hosts item `192.0.2.1 byr.pt`)
* 2021-11-20 feat: alpn settings for outbound
* 2021-11-21 fix: minor adjustments about service reloading, default DNS port, host hints, etc.
* 2021-12-16 feat: expose log and policy settings
* 2021-12-24 feat: grpc health check and initial window size
* 2021-12-25 feat: be compatible with [OpenWrt Packages: xray-core](https://github.com/openwrt/packages/tree/master/net/xray-core) again (by replacing its UCI configuration file and init script upon install). Still supports using [openwrt-xray](https://github.com/yichya/openwrt-xray). This should work in most cases and your previous configuration file of luci-app-xray is also preserved, but if you encounter problems please report.
* 2021-12-26 feat: support custom DNS port

## Changelog 2020
* 2020-11-14 feature: basic transparent proxy function
* 2020-11-15 fix: vless flow settings & compatible with busybox ip command
* 2020-12-04 feature: add xtls-rprx-splice to flow
* 2020-12-26 feature: allow to determine whether to use proxychains during build; trojan xtls flow settings

## Todo

* [x] LuCI ACL Settings
* [x] migrate to xray-core
* [x] better server role configurations
* [x] transparent proxy access control for LAN
* [x] try to be compatible with [OpenWrt Packages: xray-core](https://github.com/openwrt/packages/tree/master/net/xray-core)
* [ ] Better DNS module implementation like DoH (may involve breaking changes)
