# luci-app-xray

Focus on making the most of Xray (HTTP/HTTPS/Socks/TProxy inbounds, multiple protocols support, DNS server, bridge (reverse proxy), even HTTPS proxy server for actual HTTP services) while keeping thin and elegant.

## Warnings

* Version 3.0.0 involves a lot of breaking changes and is completely not compatible with older versions. Configurations needs to be filled in again.
* Since the last OpenWrt version with `firewall3` as default firewall implementation (which is OpenWrt 21.02.7) is now EoL, the `fw3` variant of this project is dropped.
    * Check out [tag v2.1.2](https://github.com/yichya/luci-app-xray/tree/v2.1.2) and compile fw3 variant yourself if you really need that.
* About experimental REALITY support
    * may change quite frequently so keep in mind about following warnings
    * server role support **involves breaking changes if you use HTTPS server**: certificate settings are now bound to stream security, so previously uploaded certificate and key files will disappear in LuCI, but this won't prevent Xray from using them. Your previously uploaded file are still there, just select them again in LuCI. If Xray fails to start up and complains about missing certificate files, also try picking them again.
    * legacy XTLS support has already been removed in version 1.8.0 and is also removed by this project since version 2.0.0.
* If you see `WARNING: at least one of asset files (geoip.dat, geosite.dat) is not found under /usr/share/xray. Xray may not work properly` and don't know what to do:
    * try `opkg update && opkg install xray-geodata` (at least OpenWrt 21.02 releases)
    * if that doesn't work or you are using OpenWrt 19.07 releases, see [#52](https://github.com/yichya/luci-app-xray/issues/52#issuecomment-856059905)
* This project **DOES NOT SUPPORT** the following versions of OpenWrt because of the requirements of firewall4 and cilent-side rendering LuCI:
    * LEDE / OpenWrt prior to 22.03
    * [Lean's OpenWrt Source](https://github.com/coolsnowwolf/lede) (which uses a variant of LuCI shipped with OpenWrt 18.06)

    If this is your case, use Passwall or similar projects instead (you could find links in [XTLS/Xray-core](https://github.com/XTLS/Xray-core/)).
* This project may change its code structure, configuration files format, user interface or dependencies quite frequently since it is still in its very early stage. 

## Installation (Fw4 only)

Just use `opkg -i *` to install both ipks from Releases.

## Installation (Manually building OpenWrt)

Choose one below:

* Add `src-git-full luci_app_xray https://github.com/yichya/luci-app-xray` to `feeds.conf.default` and run `./scripts/feeds update -a; ./scripts/feeds install -a` 
* Clone this repository under `package`

Then find `luci-app-xray` under `Extra Packages`.

## Changelog since 3.0.0

* 2023-09-26 Version 3.0.0 merge master
* 2023-09-27 fix: sniffing inboundTag; fix: upstream_domain_names
* 2023-10-01 fix: default configuration
* 2023-10-06 chore: code cleanup
* 2023-10-19 feat: detailed status page via metrics
* 2023-10-20 feat: better network interface control. **Requires reselection of LAN interfaces in** `Xray (preview)` -> `LAN Hosts Access Control`

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=yichya/luci-app-xray&type=Date)](https://star-history.com/#yichya/luci-app-xray&Date)
