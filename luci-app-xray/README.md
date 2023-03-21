# luci-app-xray

[luci-app-v2ray](https://github.com/yichya/luci-app-v2ray) refined to client side rendering (and switched to xray as well).

Focus on making the most of Xray (HTTP/HTTPS/Socks/TProxy inbounds, multiple protocols support, DNS server, bridge (reverse proxy), even HTTPS proxy server for actual HTTP services) while keeping thin and elegant.

## Warnings

* About experimental REALITY support
    * may change quite frequently so keep in mind about following warnings
    * currently only implemented in ucode, which means OpenWrt 22.03 versions (or master branch) and fw4 is required. Support for previous versions (19.07 / 21.02) will be added later.
    * server role support **involves breaking changes if you use HTTPS server**: certificate settings are now bound to stream security, so previously uploaded certificate and key files will disappear in LuCI, but this won't prevent Xray from using them. Your previously uploaded file are still there, just select them again in LuCI. If Xray fails to start up and complains about missing certificate files, also try picking them again.
    * legacy XTLS support has already been removed in version 1.8.0. This project will also remove legacy XTLS support in the next few updates so please migrate to xtls-rprx-vision or as soon as possible.
* Since OpenWrt 22.03 release, the recommended firewall implementation for this project is now **firewall4** with some caveats
    * currently this project still works on OpenWrt 19.07 / 21.02 versions. There's a warning about missing `kmod-nft-tproxy` when using these versions, just ignore it. This problem will be fixed later.
    * support for versions mentioned above will soon be **deprecated**, which means that most new features won't be implemented for these old versions. Check changelog for details about future changes and availability of various new features.
    * there is a possible bug in nftables 1.0.3 / 1.0.4 which breaks tproxy, so if you use master branch, make sure your source code is newer than [36bec544d73dbed46f06875fdfa570e89a40e553](https://github.com/openwrt/openwrt/commit/36bec544d73dbed46f06875fdfa570e89a40e553)
    * currently building ipk with OpenWrt SDK is **NOT** tested and is **NOT** likely to work right now. If you are building ipks yourself, use the proper version of buildroot toolchain which matches the firewall implementation (fw3 or fw4) you are using.
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

## Installation

Clone this repository under `package/extra` and find `luci-app-xray` under `Extra Packages`.

## Changelog 2023

* 2023-01-01 feat: optional restart of dnsmasq on interface change
* 2023-01-18 `[OpenWrt 22.03 or above only]` feat: option to ignore TP_SPEC_DEF_GW
* 2023-01-23 `[OpenWrt 22.03 or above only]` feat: custom configurations in outbounds. Say if you want to try [XTLS/Xray-core#1540](https://github.com/XTLS/Xray-core/pull/1540) before its release, you can specify `{"streamSettings": {"tlsSettings": {"fingerprint": "xray_random"}}}` in "Custom Options" tab of the corresponding outbound. See the help text in LuCI ui for the rules of configuration override.
* 2023-03-10 `[OpenWrt 22.03 or above only]` feat: experimental REALITY support
* 2023-03-11 feat: h2 read_idle_timeout and health_check_timeout settings

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
* 2022-06-04 `[OpenWrt 22.03 or above only]` feat: nftables support (experimental)
* 2022-06-05 feat: shadowsocks-2022 UDP over TCP support
* 2022-06-14 feat: multiple geoip direct code
* 2022-06-19 `[OpenWrt 22.03 or above only]` feat: skip proxy for specific uids / gids
* 2022-08-07 fix: avoid duplicated items in generated nftables ruleset
* 2022-08-13 fix: make sure forwarded IPs are always forwarded to Xray even for reserved addresses. Xray may not forward those requests so that manner may be changed later.
* 2022-09-01 feat: specify outbound for manual transparent proxy
* 2022-09-26 feat: show process running status
* 2022-10-02 feat: detect xray binary path; allow changing default HTTPS server port
* 2022-10-03 feat: switch to disable TCP / UDP transparent proxy
* 2022-10-05 feat: dialer proxy
* 2022-10-06 `[OpenWrt 22.03 or above only]` feat: use goto instead of jump in nftables rules
* 2022-10-29 `[OpenWrt 22.03 or above only]` feat: rewrite gen_config in ucode
* 2022-11-01 feat: support xtls-rprx-vision
* 2022-12-13 fix: force restart dnsmasq on interface change

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

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=yichya/luci-app-xray&type=Date)](https://star-history.com/#yichya/luci-app-xray&Date)
