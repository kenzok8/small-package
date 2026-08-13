<div align="center">

# 🚀 luci-app-pushbot 全能推送

**路由器报警与日志推送工具** — 支持钉钉 · 企业微信 · 飞书 · Bark · PushPlus · PushDeer · ntfy · Gotify（调试中）多渠道

[![GitHub release](https://img.shields.io/github/v/release/zzsj0928/luci-app-pushbot?style=flat-square&color=blue)](https://github.com/zzsj0928/luci-app-pushbot/releases)
[![GitHub issues](https://img.shields.io/github/issues/zzsj0928/luci-app-pushbot?style=flat-square&color=orange)](https://github.com/zzsj0928/luci-app-pushbot/issues)
[![GitHub pull requests](https://img.shields.io/github/issues-pr/zzsj0928/luci-app-pushbot?style=flat-square&color=brightgreen)](https://github.com/zzsj0928/luci-app-pushbot/pulls)
[![GitHub stars](https://img.shields.io/github/stars/zzsj0928/luci-app-pushbot?style=flat-square&color=yellow)](https://github.com/zzsj0928/luci-app-pushbot/stargazers)
[![GitHub license](https://img.shields.io/github/license/zzsj0928/luci-app-pushbot?style=flat-square)](LICENSE)

**简体中文** | [English](README.en.md)

</div>

---

# 📖 申明

- 本插件由 [tty228/luci-app-serverchan](https://github.com/tty228/luci-app-serverchan) 原创，由 **然后七年** @zzsj0928 重新修改为本插件，适配钉钉机器人 API。
- 本插件工作在：**OpenWRT**
- 自 **v5.10** 起彻底去 Lua、去 CBI，采用**纯 ucode 架构**，仅支持 LuCI ≥ 23.05（详细支持平台与变更见下方更新日志）。

# 📝 更新日志

- **2026-08-13**（v5.13）：拉黑功能增强（白名单 / IPv6 / 即时应用），主版本 5.12 → 5.13
  - 新增：**白名单**——支持单个 IP 与标准 IP 段（CIDR），如 `192.168.1.5` / `10.1.1.0/24` / `2001:db8::1` / `fd00::/32`，多个用空格分隔；白名单内的 IP 即使登录失败也不会被拉黑
  - 新增：**IPv6 拉黑**——黑名单支持 IPv6 地址与网段（此前仅 IPv4）
  - 优化：**拉黑即时生效**——新增 / 修改 / 删除 / 清空黑名单保存后立即应用到防火墙，无需等待轮询或重启
  - 修复：清空黑名单后规则彻底移除（此前可能残留规则，需手动重启防火墙才解除）
- **2026-08-12**（v5.12-r15）：
  - 新增：Gotify 推送渠道（调试中）
  - 新增：色彩定义卡片「测试色彩」按钮（保存配置并立即推送验证）
  - 新增：版本角标自动读取安装版本，点击角标在浏览器端检查 GitHub 更新（8 秒超时，磨砂弹窗提示，0.5s 淡入 / 4s 停留）
  - 修复：MT798x 平台接口下拉无选项（busybox 无 timeout 命令）；OpenWrt 23.05 ipk 缺失 r 小版本
- **2026-08-09**（v5.12）：新增 Gotify 渠道支持（调试中），主版本 5.11 → 5.12
- **2026-08-09**（v5.11）：多项修复与增强
  - 主题联动：自动适配 argon / zargon / liquid / 系统的明暗模式（跟随当前启用主题）
  - ntfy：修复换行显示，Token 与自建服务器改为开关控制
  - PushPlus：支持全部渠道（APP/插件/ClawBot/语音等）与渠道编码
  - 界面全面中文化，测试按钮更名为"测试渠道 / 测试定时"
  - 修复多处翻译失效与页面 JS 报错
- **2026-08-06**：全面国际化与多项优化
  - 全面国际化：界面以英文为源语言，安装 `luci-i18n-pushbot-zh-cn` 翻译包后自动显示中文
  - 汉化包版本与主包同步跟进
  - GitHub Actions 新增语言包上传（x86 / MT798x × ipk / apk 四批次）
  - UI 布局优化（版本胶囊、状态徽章、标题卡片描述）
  - 点击运行状态徽章即可重启 pushbot 服务
  - 修复国际化引起的 JS 结构问题
- **2026-08-05**：彻底去 Lua、去 CBI，纯 ucode 架构
  - 仅支持 LuCI ≥ 23.05（openwrt-24.10 / 25.x / master）及已同步 ucode dispatcher 的分支
  - 实测平台：
    - openwrt/luci master ✅
    - coolsnowwolf/lede (openwrt-25.12) ✅
    - padavanonly/immortalwrt-mt798x-6.6 (openwrt-24.10) ✅
    - immortalwrt/luci master（未实测，理论上兼容）
  - OpenWrt ≤ 22.03、LEDE 17.01 等旧环境请使用 v5.09 及之前版本（lua 架构）
- **2026-08-04**：允许自定义消息字段颜色，增加在线实时预览，无需再测试发送看预览
- **2026-07-27**：修改免打扰逻辑，从源头处理 —— 被过滤的设备在上线/下线、在线设备列表、定时推送的设备列表都会被过滤（介意请停留在 v5.07 或以前）
- **2026-07-26**：清理 Lua CBI 表单，全面转向 JS+XHR Tab 卡片式 UI
- **2026-07-25**：全面重构 Lua CBI，移除旧版界面，全新的 Tab 卡片式 UI（初始配置加载优化、IP 拉黑支持 nftables / iptables 双模式）
- **2026-07-24**：支持 APK，改为现代 UI
- **2021-09-11**：支持 Bark 群组，群组名默认为设备名
- **2021-09-01**：增加依赖 jq，请重新编译或在安装前同步安装 jq

# 🎯 功能概览

## 基本设置

| 模块 | 功能 |
|------|------|
| 运行控制 | 插件启用/禁用开关、精简模式（精简设备列表 / 当前时间 / 只推送标题） |
| 推送模式 | 支持 钉钉、企业微信、飞书、Bark、PushPlus（全渠道）、PushDeer、ntfy、Gotify（调试中）、自定义推送 等多种推送渠道 |
| 终端信息 | MAC 设备信息数据库（简化版 / 完整版 / 网络查询）、设备别名管理 |
| 免打扰 | 免打扰时段设置（脚本挂起 / 静默模式）、MAC 过滤（白名单 / 黑名单 / 接口过滤、在线 / 离线免打扰） |

## 推送内容

| 模块 | 功能 |
|------|------|
| 网络监控 | IPv4 / IPv6 变更通知（支持接口获取或 URL 获取）、设备上线/下线通知 |
| 性能监控 | CPU 负载报警及阈值、CPU 温度报警及阈值、设备异常流量检测及每分钟流量限制、异常流量免打扰及关注列表 |
| 安全监控 | Web 登录提醒、SSH 登录提醒、Web / SSH 错误尝试提醒、错误尝试次数、自动拉黑及拉黑时间、IP 白名单 / 黑名单 |

## 定时推送

| 模块 | 功能 |
|------|------|
| 定时任务 | 支持定时发送（每日最多三个时间点）和间隔发送 |
| 推送内容 | 系统运行情况、设备温度、WAN 信息、客户端列表 |
| 其他 | 推送标题自定义、全球互联检测超时时间、手动发送按钮 |

## 高级设置

| 模块 | 功能 |
|------|------|
| 设备监测 | 设备上线/离线检测超时时间、最大并发进程数、离线检测次数 |
| 温度监测 | 自定义温度读取命令（支持默认 / PVE 虚拟机 / 自定义命令）、PVE 宿主机 SSH 配置、温度测试 |
| 色彩定义 | 自定义主标题 / 成功 / 失败 / 客户端名 / 模块标题颜色（#RRGGBB），支持在线实时预览推送效果 |
| 无人值守 | 无人值守任务开关、仅在免打扰时段重拨、网络断开时操作（重启路由器 / 重新拨号 / 自动修复）、关注列表、定时重启（系统运行时间 / 网络在线时间触发）、重拨尝试获取公网 IP 及当天最大重试次数 |

## 在线设备

实时查看当前在线设备列表（主机名、MAC 地址、IP 地址、在线时间）

## 日志

实时查看推送日志，支持自动刷新和手动清除

# 📥 下载

- [luci-app-pushbot Releases](https://github.com/zzsj0928/luci-app-pushbot/releases)

## 关联下载

- [luci-app-serverchan](https://github.com/tty228/luci-app-serverchan/releases)
- [wrtbwmon](https://github.com/brvphoenix/wrtbwmon)
- [luci-app-wrtbwmon](https://github.com/brvphoenix/luci-app-wrtbwmon)

# 💡 说明

- 精力有限，新功能看需开发；
- 欢迎各种代码提交；
- 潘多拉系统、或不支持 sh 的系统，请将脚本开头 `#!/bin/sh` 改为 `#!/bin/bash`，或手动安装 `sh`；
- 提交 bug 时请尽量带上设备信息、日志与描述（如执行 `/usr/bin/pushbot/pushbot` 后的提示、日志信息、`/tmp/pushbot/ipAddress` 文件信息）。

## 已知问题

- 直接关闭接口时，该接口的离线设备会忽略检测；
- 部分设备无法读取到设备名，脚本使用 `cat /var/dhcp.leases` 命令读取设备名，如果 dhcp 中不存在设备名则无法读取（如二级路由设备、静态 IP 设备），请使用设备名备注。

---

# 🖼 显示效果

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

# 📛 改名公告

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
