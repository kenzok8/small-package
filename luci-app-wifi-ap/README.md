# luci-app-wifi-ap

## 项目简介
luci-app-wifi-ap 是基于 OpenWrt 的 WiFi AP 统一管理前后端应用，配合 luci-app-wifi-ac 实现自动发现、远程命令、固件升级、日志采集、趋势数据、WebSocket 推送等功能，适配 AC/AP 集中运维场景。

## 主要功能
- **自动发现**：支持 UDP、mDNS、HTTP 主动注册，AP 端自动上报，AC 端集中管理。
- **远程命令**：支持批量/单台重启、升级、配置同步、模板应用等，ACK 机制确保可靠。
- **固件升级**：支持分块上传、断点续传、失败回滚，升级进度实时上报。
- **日志与趋势**：结构化日志采集、自动轮转，性能趋势数据采集与持久化。
- **WebSocket 推送**：设备状态、趋势数据等实时推送前端，提升运维体验。
- **安全机制**：Token、签名、IP 白名单，支持 HTTPS。

## 目录结构
```
luci-app-wifi-ap/
├── Makefile
├── README.md
├── AP端配合功能清单.md
├── files/
│   ├── etc/
│   │   ├── config/wifi-ap
│   │   ├── init.d/wifi-ap
│   │   └── logrotate.d/wifi-ap
│   ├── usr/
│   │   ├── bin/wifi-ap
│   │   └── sbin/
│   │       ├── wifi-ap-firmware-upload.sh
│   │       ├── wifi-ap-log-clean.sh
│   │       └── wifi-ap-trend-collector.sh
├── luasrc/
│   ├── controller/wifi-ap.lua
│   ├── model/cbi/wifi_ap.lua
│   └── view/wifi-ap/index.htm
├── htdocs/
│   └── luci-static/resources/
│       ├── wifi-ap.js
│       └── wifi-ap.css
```

## 关键配置说明
- `/etc/config/wifi-ap`：全局参数、角色权限、设备静态信息等。
- `/etc/wifi-ap/token`、`/etc/wifi-ap/secret`：通信Token与签名密钥，建议生产环境使用复杂随机字符串。
- `/tmp/wifi-ac/`：运行时临时数据目录，自动发现、注册、状态等JSON文件均存于此。

## 主要脚本说明
- `wifi-ap`：AP端主守护进程，负责信息采集、自动发现、注册、心跳、事件推送等。
- `wifi-ap-firmware-upload.sh`：固件分块上传与升级脚本。
- `wifi-ap-log-clean.sh`：日志自动清理脚本。
- `wifi-ap-trend-collector.sh`：性能趋势数据采集脚本。

## 前端功能
- 设备列表、批量操作、实时状态、日志导出、趋势图等。
- 支持 WebSocket 实时推送，自动刷新设备状态。

## 依赖
- OpenWrt 21.02/22.03/23.05
- luci-base、luci-lib-jsonc、luci-lib-nixio、ubus、uhttpd、iwinfo、jq、curl、avahi-daemon、logrotate 等

## 常见问题
- `/tmp/wifi-ac/` 目录下无数据：请检查 `wifi-ap` 守护进程是否正常运行，相关脚本是否有执行权限。
- 依赖缺失：请根据 Makefile 安装所需依赖包。

## 参考
- [AP端配合功能清单.md](AP端配合功能清单.md)
- luci-app-wifi-ac 项目