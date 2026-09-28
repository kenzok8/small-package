<div align="center">

# 🚀 luci-app-pushbot PushBot

**Router alert & log push tool** — DingTalk · WeCom · Feishu · Bark · PushPlus · PushDeer · ntfy · Gotify · WxPusher

[![GitHub release](https://img.shields.io/github/v/release/zzsj0928/luci-app-pushbot?style=flat-square&color=blue)](https://github.com/zzsj0928/luci-app-pushbot/releases)
[![GitHub issues](https://img.shields.io/github/issues/zzsj0928/luci-app-pushbot?style=flat-square&color=orange)](https://github.com/zzsj0928/luci-app-pushbot/issues)
[![GitHub pull requests](https://img.shields.io/github/issues-pr/zzsj0928/luci-app-pushbot?style=flat-square&color=brightgreen)](https://github.com/zzsj0928/luci-app-pushbot/pulls)
[![GitHub stars](https://img.shields.io/github/stars/zzsj0928/luci-app-pushbot?style=flat-square&color=yellow)](https://github.com/zzsj0928/luci-app-pushbot/stargazers)
[![GitHub license](https://img.shields.io/github/license/zzsj0928/luci-app-pushbot?style=flat-square)](LICENSE)

[简体中文](../README.md) | **English**

</div>

---

## 📖 About

- Originally created by [tty228/luci-app-serverchan](https://github.com/tty228/luci-app-serverchan), rewritten by **Zed-7nian** @zzsj0928 for the DingTalk bot API.
- Works on: **OpenWRT**
- Since **v5.10**: fully removed Lua and CBI — **pure ucode architecture**, requires LuCI ≥ 23.05 (see the changelog below for supported platforms and details).

## 📝 Changelog

- **2026-09-27** (v6.01): Online update fixes & config management
  - Fixed+Improved: **Online update** — fixed IPK update failure, lost translations (English UI) after update, and occasional hangs; wait 30s → 10s with instant refresh after install; added Clear Packages button; "untrusted" prompt no longer appears after one install (APK signature trust)
  - Added: **Config Management** — one-click factory reset, or reset system options only while keeping the current channel's Token/UID/topics
  - Fixed+Improved: **Master switch** — no residual pushes after turning off; the Enabled toggle now saves and starts/stops the service on click, no need to press Save & Apply
  - Fixed: **Channel validation** — WxPusher/ntfy/Gotify-only setups no longer falsely report a missing Token; preview no longer flags unchanged lists; test buttons prompt to save first when settings changed
  - Improved: **UI** — card elevation shadows (light/dark), extra top spacing, mobile save buttons wrap instead of squeezing; renamed "Traffic limit per interval" to **"Traffic alert threshold"**
  - Added: **OpenWrt 25.12 manual build** — trigger from the Actions tab, artifacts published under `OpenWRT25.12-*` releases

Full history → [changelogs.en.md](changelogs.en.md)

## 🎯 Features

### Basic Settings

| Module | Description |
|--------|-------------|
| Run Control | Enable/disable switch, compact mode (compact device list / current time / push title only) |
| Push Mode | DingTalk, WeCom, Feishu, Bark, PushPlus (all channels), PushDeer, ntfy, Gotify, WxPusher, custom push |
| Terminal Info | MAC device database (compact / full / network lookup), device aliases |
| Do Not Disturb | DND hours (pause script / silent mode), MAC filter (whitelist / blacklist / interface filter, online / offline DND) |

### Push Content

| Module | Description |
|--------|-------------|
| Network Monitor | IPv4/IPv6 change notifications (via interface or URL), device online/offline notifications |
| Performance Monitor | CPU load alert + threshold, CPU temperature alert + threshold, abnormal traffic detection with per-minute limit, traffic DND and watchlist |
| Security Monitor | Web/SSH login alerts, failed attempt alerts, auto blacklist + duration, IP whitelist/blacklist |

### Scheduled Push

| Module | Description |
|--------|-------------|
| Scheduled tasks | Scheduled send (up to 3 times daily) and interval send |
| Push content | System status, device temperature, WAN info, client list |
| Other | Custom push title, global connectivity timeout, send-now button |

### Advanced

| Module | Description |
|--------|-------------|
| Device Monitor | Online/offline detection timeouts, max concurrent processes, offline detection count |
| Temperature Monitor | Custom temperature command (default / PVE VM / custom), PVE host SSH config, temperature test |
| Color Settings | Custom title / success / failure / client name / module title colors (#RRGGBB) with live preview |
| Unattended | Unattended task toggle, redial only during DND hours, action on network down (reboot / redial / auto-repair), watchlist, scheduled reboot (uptime / network uptime triggers), redial to obtain public IP with daily retry limit |

### Online Devices

View the current online device list in real time (hostname, MAC, IP, online time)

#$# Logs

View push logs in real time, with auto-refresh and manual clear

## 📥 Download

- [luci-app-pushbot Releases](https://github.com/zzsj0928/luci-app-pushbot/releases)

### Related

- [luci-app-serverchan](https://github.com/tty228/luci-app-serverchan/releases)
- [wrtbwmon](https://github.com/brvphoenix/wrtbwmon)
- [luci-app-wrtbwmon](https://github.com/brvphoenix/luci-app-wrtbwmon)

## 💡 Notes

- Limited time — new features are developed on demand;
- Pull requests are welcome;
- On PandoraBox or systems without `sh`, change the script header `#!/bin/sh` to `#!/bin/bash`, or install `sh` manually;
- When reporting a bug, please include device info, logs and description (e.g. output of `/usr/bin/pushbot/pushbot`, log files, `/tmp/pushbot/ipAddress`).

## Known Issues

- Devices on an interface that is directly disabled will not be detected as offline;
- Some devices cannot be resolved to a hostname — the script reads names from `/var/dhcp.leases`; if absent (e.g. second-level router, static IP devices), use device aliases instead.

---

## 🖼 Screenshots

- **Modern UI, dark-mode compatible, better architecture**

<img src="https://raw.githubusercontent.com/zzsj0928/ReadmeContents/main/Pushbot/Pushbot.v5.Dark.png" width="850">
<img src="https://raw.githubusercontent.com/zzsj0928/ReadmeContents/main/Pushbot/Pushbot.v5.Light.png" width="850">

<br><br/>

- **Notification bar: push title at a glance, grouped by device**

<img src="https://raw.githubusercontent.com/zzsj0928/ReadmeContents/main/Pushbot/Msg.Notification.jpg" width="500">

<br><br/>

- **Message list: latest push titles**

<img src="https://raw.githubusercontent.com/zzsj0928/ReadmeContents/main/Pushbot/Msg.List.jpg" width="500">

<br><br/>

- **Message content: all push info at a glance**

<img src="https://raw.githubusercontent.com/zzsj0928/ReadmeContents/main/Pushbot/MsgContentDetials.jpeg" width="500">

## 🍡Buy me a cup of TOKEN 😜
**Appreciate Your Like!**
![Awards](https://raw.githubusercontent.com/zzsj0928/ReadmeContents/master/general/donate-zed.jpg)

## 📛 Rename Notice

Since **2021-04-25**, `luci-app-serverchand` was renamed to **`luci-app-pushbot`**.

To build from source:

```bash
# old:
# git clone https://github.com/zzsj0928/luci-app-serverchand package/luci-app-serverchand
# new:
git clone https://github.com/zzsj0928/luci-app-pushbot package/luci-app-pushbot
```

Change in `.config`:

```
CONFIG_PACKAGE_luci-app-serverchand=y
```

to:

```
CONFIG_PACKAGE_luci-app-pushbot=y
```

> Note: back up your serverchand config before the rename and reconfigure PushBot.

**Thanks for your support** 🙏
