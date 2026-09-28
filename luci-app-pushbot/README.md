<div align="center">

# 🚀 luci-app-pushbot 全能推送

**路由器报警与日志推送工具** — 支持钉钉 · 企业微信 · 飞书 · Bark · PushPlus · PushDeer · ntfy · Gotify · WxPusher 多渠道

[![GitHub release](https://img.shields.io/github/v/release/zzsj0928/luci-app-pushbot?style=flat-square&color=blue)](https://github.com/zzsj0928/luci-app-pushbot/releases)
[![GitHub issues](https://img.shields.io/github/issues/zzsj0928/luci-app-pushbot?style=flat-square&color=orange)](https://github.com/zzsj0928/luci-app-pushbot/issues)
[![GitHub pull requests](https://img.shields.io/github/issues-pr/zzsj0928/luci-app-pushbot?style=flat-square&color=brightgreen)](https://github.com/zzsj0928/luci-app-pushbot/pulls)
[![GitHub stars](https://img.shields.io/github/stars/zzsj0928/luci-app-pushbot?style=flat-square&color=yellow)](https://github.com/zzsj0928/luci-app-pushbot/stargazers)
[![GitHub license](https://img.shields.io/github/license/zzsj0928/luci-app-pushbot?style=flat-square)](LICENSE)

**简体中文** | [English](README.en.md)

</div>

---

## 📖 申明

- 本插件由 [tty228/luci-app-serverchan](https://github.com/tty228/luci-app-serverchan) 原创，由 **然后七年** @zzsj0928 重新修改为本插件，适配钉钉机器人 API。
- 本插件工作在：**OpenWRT**
- 自 **v5.10** 起彻底去 Lua、去 CBI，采用**纯 ucode 架构**，仅支持 LuCI ≥ 23.05（详细支持平台与变更见下方更新日志）。

## 📝 更新日志

- **2026-09-27**（v6.01）：在线更新修复与配置管理
  - 修复+优化：**在线更新**——修复 IPK 更新失败、更新后界面丢失翻译与偶发卡死；等待 30 秒 → 10 秒装好即刷新；新增清除下载；安装一次后不再提示"允许未信任"
  - 新增：**配置管理**——一键恢复出厂设置，或仅重置系统项、保留当前推送渠道的 Token/UID/主题
  - 修复+优化：**总开关**——关闭后不再残留推送；「已启用」点击即保存并启停服务，无需再点保存
  - 修复：**渠道校验**——仅用 WxPusher/ntfy/Gotify 不再误报缺 Token；预览不再误报未改动项；测试按钮检测到改动会先提示保存再测
  - 优化：**界面**——卡片立体投影（亮/暗黑）、页面下移留白、移动端保存按钮换行；「时间间隔内流量限制」改名**「流量报警阈值」**
  - 新增：**OpenWrt 25.12 源手动编译**——Actions 手动触发，产物发布于 `OpenWRT25.12-*` Release

完整历史更新日志见 → [changelogs.md](changelogs.md)

## 🎯 功能概览

### 基本设置

| 模块 | 功能 |
|------|------|
| 运行控制 | 插件启用/禁用开关、精简模式（精简设备列表 / 当前时间 / 只推送标题） |
| 推送模式 | 支持 钉钉、企业微信、飞书、Bark、PushPlus（全渠道）、PushDeer、ntfy、Gotify、WxPusher、自定义推送 等多种推送渠道 |
| 终端信息 | MAC 设备信息数据库（简化版 / 完整版 / 网络查询）、设备别名管理 |
| 免打扰 | 免打扰时段设置（脚本挂起 / 静默模式）、MAC 过滤（白名单 / 黑名单 / 接口过滤、在线 / 离线免打扰） |

### 推送内容

| 模块 | 功能 |
|------|------|
| 网络监控 | IPv4 / IPv6 变更通知（支持接口获取或 URL 获取）、设备上线/下线通知 |
| 性能监控 | CPU 负载报警及阈值、CPU 温度报警及阈值、设备异常流量检测及每分钟流量限制、异常流量免打扰及关注列表 |
| 安全监控 | Web 登录提醒、SSH 登录提醒、Web / SSH 错误尝试提醒、错误尝试次数、自动拉黑及拉黑时间、IP 白名单 / 黑名单 |

### 定时推送

| 模块 | 功能 |
|------|------|
| 定时任务 | 支持定时发送（每日最多三个时间点）和间隔发送 |
| 推送内容 | 系统运行情况、设备温度、WAN 信息、客户端列表 |
| 其他 | 推送标题自定义、全球互联检测超时时间、手动发送按钮 |

### 高级设置

| 模块 | 功能 |
|------|------|
| 设备监测 | 设备上线/离线检测超时时间、最大并发进程数、离线检测次数 |
| 温度监测 | 自定义温度读取命令（支持默认 / PVE 虚拟机 / 自定义命令）、PVE 宿主机 SSH 配置、温度测试 |
| 色彩定义 | 自定义主标题 / 成功 / 失败 / 客户端名 / 模块标题颜色（#RRGGBB），支持在线实时预览推送效果 |
| 无人值守 | 无人值守任务开关、仅在免打扰时段重拨、网络断开时操作（重启路由器 / 重新拨号 / 自动修复）、关注列表、定时重启（系统运行时间 / 网络在线时间触发）、重拨尝试获取公网 IP 及当天最大重试次数 |

### 在线设备

实时查看当前在线设备列表（主机名、MAC 地址、IP 地址、在线时间）

### 日志

实时查看推送日志，支持自动刷新和手动清除

## 📥 下载

- [luci-app-pushbot Releases](https://github.com/zzsj0928/luci-app-pushbot/releases)

### 关联下载

- [luci-app-serverchan](https://github.com/tty228/luci-app-serverchan/releases)
- [wrtbwmon](https://github.com/brvphoenix/wrtbwmon)
- [luci-app-wrtbwmon](https://github.com/brvphoenix/luci-app-wrtbwmon)

## 💡 说明

- 精力有限，新功能看需开发；
- 欢迎各种代码提交；
- 潘多拉系统、或不支持 sh 的系统，请将脚本开头 `#!/bin/sh` 改为 `#!/bin/bash`，或手动安装 `sh`；
- 提交 bug 时请尽量带上设备信息、日志与描述（如执行 `/usr/bin/pushbot/pushbot` 后的提示、日志信息、`/tmp/pushbot/ipAddress` 文件信息）。

## 已知问题

- 直接关闭接口时，该接口的离线设备会忽略检测；
- 部分设备无法读取到设备名，脚本使用 `cat /var/dhcp.leases` 命令读取设备名，如果 dhcp 中不存在设备名则无法读取（如二级路由设备、静态 IP 设备），请使用设备名备注。

---

## 🖼 显示效果

- **新的现代 UI 设计，兼容暗黑模式，更合理的架构**

<img src="https://raw.githubusercontent.com/zzsj0928/ReadmeContents/main/Pushbot/Pushbot.v5.Dark.png" width="850">
<img src="https://raw.githubusercontent.com/zzsj0928/ReadmeContents/main/Pushbot/Pushbot.v5.Light.png" width="850">

<br><br/>

- **通知栏：直接显示推送主题，一目了然，按设备不同分组显示**

<img src="https://raw.githubusercontent.com/zzsj0928/ReadmeContents/main/Pushbot/Msg.Notification.jpg" width="500">

<br><br/>

- **消息列表：直接显示最新推送的标题**

<img src="https://raw.githubusercontent.com/zzsj0928/ReadmeContents/main/Pushbot/Msg.List.jpg" width="500">

<br><br/>

- **消息内容：直接显示所有推送信息，不用二次点开再查看**

<img src="https://raw.githubusercontent.com/zzsj0928/ReadmeContents/main/Pushbot/MsgContentDetials.jpeg" width="500">

## 🍡赏我一把 Token
**制作不易，感谢支持**
![赞赠](https://raw.githubusercontent.com/zzsj0928/ReadmeContents/master/general/donate-zed.jpg)

## 📛 改名公告

**2021年04月25日** 起 `luci-app-serverchand` 改名为 **`luci-app-pushbot`**。

如需拉取编译：

```bash
# 旧：
# git clone https://github.com/zzsj0928/luci-app-serverchand package/luci-app-serverchand
# 新：
git clone https://github.com/zzsj0928/luci-app-pushbot package/luci-app-pushbot
```

并把 `.config` 中：

```
CONFIG_PACKAGE_luci-app-serverchand=y
```

改为：

```
CONFIG_PACKAGE_luci-app-pushbot=y
```

> 注意：本次改名需要提前备份 serverchand 配置，并于 PushBot 中重新配置。

**再次谢谢各位支持** 🙏
