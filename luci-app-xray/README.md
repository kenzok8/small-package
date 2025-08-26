# luci-app-xray

Focus on making the most of Xray (HTTP/HTTPS/Socks/TProxy inbounds, multiple protocols support, DNS server, bridge (reverse proxy), even HTTPS proxy server for actual HTTP services) while keeping thin and elegant.

## Warnings

* For OpenWrt 24.10 and SNAPSHOT users, dnsmasq integration options need to be changed. See the last comment in [#425](https://github.com/yichya/luci-app-xray/issues/425#issuecomment-2494295834) for details.
* For security concerns, global SOCKS / HTTP inbound (listen on 0.0.0.0, port 1080 / 1081 by default) is deprecated and will be removed in next major version (4.0.0).
    * These settings are moved to preview app
    * Use Extra Inbound to manually add ports (avoid using common ports like 1080, also set listen addresses carefully) and adjust related workloads to use that.
* Since version 3.2.0 sniffing and global custom settings are deprecated.
    * These settings are moved to preview app. See below for details to enable preview app.
    * Global custom settings will be removed in version 4.0.0. Use "Custom Configuration Hook" for global custom settings.
    * Sniffing might get completely reimplemented later. Use FakeDNS instead of sniffing to avoid incompatibilities.
* This project **DOES NOT SUPPORT** the following versions of OpenWrt because of the requirements of firewall4 and cilent-side rendering LuCI:
    * LEDE / OpenWrt prior to 22.03
    * [Lean's OpenWrt Source](https://github.com/coolsnowwolf/lede) (which uses a variant of LuCI shipped with OpenWrt 18.06)

    If this is your case, use Passwall or similar projects instead (you could find links in [XTLS/Xray-core](https://github.com/XTLS/Xray-core/)).
* About experimental REALITY support
    * it may change quite frequently (before the release of official documents about the protocol). Keep in mind for (maybe) breaking changes.
* If you see `WARNING: at least one of asset files (geoip.dat, geosite.dat) is not found under /usr/share/xray. Xray may not work properly` and don't know what to do:
    * try `opkg update && opkg install v2ray-geoip v2ray-geosite`
    * if that doesn't work, see [#52](https://github.com/yichya/luci-app-xray/issues/52#issuecomment-856059905)
* This project may change its code structure, configuration files format, user interface or dependencies quite frequently since it is still in its very early stage.

## Installation (Manually building OpenWrt)

Choose one below:

* Add `src-git-full luci_app_xray https://github.com/yichya/luci-app-xray` to `feeds.conf.default` and run `./scripts/feeds update -a; ./scripts/feeds install -a`
* Clone this repository under `package`

Then find `luci-app-xray` under `Extra Packages`.

## Installation (Use GitHub actions to build ipks)

Fork this repository and:

* Create a release by pushing a tag
* Wait until actions finish
* Use `opkg -i *` to install both ipks from Releases.

## Enable preview app

Some features are deprecated / unstable so they are placed in preview app. To enable preview app:

* Select `Preview or Deprecated` in `Extra Settings` tab
* Reboot your router
* There will be a new menu option `Xray (preview)` in `Services`

## Changelog since 3.6.0

* 2025-05-13 feat: geodata reader
* 2025-07-20 feat: geoip in manual transparent proxy
* 2025-07-24 fix: geosite browser search
* 2025-07-27 fix: dynamic direct: only cover global servers; increase default timeout
* 2025-08-20 fix: dynamic direct connection tracking
* 2025-08-26 fix: dnsmasq global integration mode

## Changelog since 3.5.0

* 2024-11-26 chore: bump status version
* 2024-11-27 chore: use OpenWrt SDK 23.05.5 to avoid using apk
* 2025-01-05 fix: direct output; remove unused check of geoip direct list

## Changelog since 3.4.0

* 2024-02-18 chore: optimize code style; bump version
* 2024-02-19 fix: several DNS related validation
* 2024-02-20 fix: domain match priority; stricter resolve options; socks / http auth
* 2024-02-23 chore: bump version to 3.4.1
* 2024-02-27 fix: block requests when leastPing not ready
* 2024-03-08 feat: multiple ports for one outbound
* 2024-03-11 feat: expectIPs for outbound domain resolving; restart on dnsmasq config change
* 2024-03-14 feat: add version info display in status
* 2024-03-17 fix: add ACL for version info
* 2024-04-23 fix: use zstd for OpenWrt SDK decompression
* 2024-05-03 fix: reality deserialization issue
* 2024-06-26 feat: support ext in geoip direct codes
* 2024-07-26 chore: minor code and style fixes
* 2024-11-22 fix: dnsmasq jail adaptation; firewall improvements
* 2024-11-25 feat: basic splithttp support
* 2024-11-26 feat: httpupgrade support; avoid overriding mark

## Changelog since 3.3.0

* 2024-01-19 chore: bump version
* 2024-01-24 feat: add alias to LAN Hosts Access Control
* 2024-02-04 fix: avoid firewall restart failure & some minor adjustments
* 2024-02-16 feat: dns hijacking preview; deprecate global http / socks inbound
* 2024-02-17 feat: add username / password for extra socks / http inbound

## Changelog since 3.2.0

* 2023-12-20 chore: bump version
* 2023-12-22 chore: optimize list folded format; add roundRobin balancer
* 2024-01-04 chore: start later than sysntpd; change firewall include file path
* 2024-01-18 feat: make "Resolve Domain via DNS" available to all outbounds
* 2024-01-19 feat: socks / http outbound

## Changelog since 3.1.0

* 2023-10-24 chore: bump version
* 2023-10-25 fix: set required for some fields; remove unused code
* 2023-10-26 fix: allow empty selection for extra inbound outbound balancer
* 2023-10-30 fix: blocked as nxdomain for IPv6
* 2023-10-31 chore: bump version to 3.1.1
* 2023-11-01 feat: custom configuration hook
* 2023-11-02 feat: specify DNS to resolve outbound server name
* 2023-11-30 fix: dialer proxy tag
* 2023-12-14 fix: default gateway
* 2023-12-20 chore: deprecate sniffing; move some preview features to main app; add custom configuration hook; refactor web files

## Changelog since 3.0.0

* 2023-09-26 Version 3.0.0 merge master
* 2023-09-27 fix: sniffing inboundTag; fix: upstream_domain_names
* 2023-10-01 fix: default configuration
* 2023-10-06 chore: code cleanup
* 2023-10-19 feat: detailed status page via metrics
* 2023-10-20 feat: better network interface control. **Requires reselection of LAN interfaces in** `Xray (preview)` -> `LAN Hosts Access Control`

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=yichya/luci-app-xray&type=Date)](https://star-history.com/#yichya/luci-app-xray&Date)
