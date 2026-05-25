# luci-app-wifi-ap 适配 luci-app-wifi-ac 功能清单适配性检查

## 1. 已适配AC端实现的功能

- **设备信息与状态上报**
  - 提供标准ubus接口（`wifi.status`），支持静态/动态信息上报，结构标准化（见controller/wifi-ap.lua、ap_agent脚本）。
  - 支持心跳机制（ap_agent定时上报/接口演示）。
  - 支持主动和被动拉取。

- **远程命令响应**
  - 实现标准ubus接口（`wifi.device`），支持远程重启、升级、配置同步、模板应用、信道/功率/接入数设置等（controller/wifi-ap.lua）。
  - 支持批量操作ACK、失败重试，所有命令返回 `{code, msg}` 结构。
  - 支持UDP命令监听与ACK机制（ap_agent脚本、ubus示例）。

- **自动发现与注册**
  - 支持UDP广播发现、mDNS发现（需mDNS responder）、HTTP主动注册（ap_agent脚本实现）。
  - 守护进程监听UDP/mDNS/HTTP，采集结果写入 `/tmp/wifi-ac/discovered_devices.json`、`mdns_devices.json`、`http_devices.json`。
  - 支持跨网段AP管理（主动HTTP注册、mDNS等）。

- **固件升级与断点续传**
  - 支持固件包分块接收、断点续传、失败回滚（wifi-ap-firmware-upload.sh脚本、API接口）。
  - 升级进度/状态通过日志和API上报。

- **配置同步与模板应用**
  - 能接收AC下发的配置模板（UCI/JSON），自动应用并反馈结果（controller/wifi-ap.lua）。
  - 支持配置参数热加载（无需重启服务）。
  - 支持 `ubus call wifi.device '{"mac":"...","action":"apply_template","tpl":...}'`。

- **日志采集与上报**
  - 本地运行日志、操作日志采集，结构标准化（含时间、命令、用户、结果）。
  - 日志轮转与自动清理（logrotate配置、清理脚本）。
  - 日志API支持多条件筛选、导出、权限校验。

- **趋势数据采集与持久化**
  - 支持定时采集性能数据，持久化到json（trend.json），API支持多指标、时间范围查询。

- **安全认证与权限控制**
  - 与AC通信接口支持Token、签名、IP白名单校验（ap_agent脚本、API接口）。
  - 敏感API强制Token校验，签名算法支持HMAC-SHA256（优先openssl，降级md5sum）。
  - 日志API细粒度权限校验。

- **WebSocket/事件推送（可选）**
  - 关键事件（上线/离线、升级结果、异常告警等）支持ubus事件推送，WebSocket接口预留（前端/后端注释）。

- **其它建议与扩展点**
  - 支持多AC冗余注册。
  - 所有接口RESTful标准化，参数/返回结构统一（如 `{code,msg,data}`）。
  - 三方AP适配时保留接口和注释，便于后续扩展。

---

## 2. 未完全适配或待完善的功能

- **WebSocket实时推送服务**
完善其他相关文件（包含lua/htm/js/css）内容（缺少文件可以按照目录规则创建）；
1.后端WebSocket服务（如uhttpd/ws/lua-websockets）仅预留接口，未完全实现AP端主动推送（可选，需守护进程或uhttpd扩展）。
2.HTTPS通信建议已在ap_agent脚本实现（curl支持https），但证书自动管理、强制HTTPS等需结合实际部署完善。
3.AP端仅支持基础命令和数据采集给AC，便于AC来实现复杂负载均衡、干扰感知、信道热力图等高级算法
- **高级性能优化/负载均衡算法**
  - AP端仅支持基础命令和数据采集给AC，便于AC来实现复杂负载均衡、干扰感知、信道热力图等高级算法
- **角色/权限配置文件管理**
  - 角色/权限配置文件（如roles.json）管理主要在AC端，AP端日志API支持简单权限校验，细粒度权限可进一步完善。

- **HTTPS通信强制与证书管理**
  - HTTPS通信建议已在ap_agent脚本实现（curl支持https），但证书自动管理、强制HTTPS等需结合实际部署完善。

- **多厂商/三方AP深度适配**
  - 主流三方AP适配接口已预留（如功率调节、信道设置等），但具体厂商私有API需根据实际设备扩展。

- **趋势数据持久化到sqlite3**
  - 目前trend数据为json文件，持久化到sqlite3可选实现（接口已预留）。

---

## 3. 适配性结论

luci-app-wifi-ap 已基本完成与 luci-app-wifi-ac 的核心功能适配，涵盖设备信息/状态上报、远程命令、自动发现、固件升级、配置同步、日志、趋势、安全等主要模块。部分高级功能（如WebSocket推送、复杂负载均衡算法、深度三方AP适配）可根据实际需求进一步完善。

**参考文档/代码：**
- wifi-ap-README.md / wifi-ap-README - 副本.md
- AP端配合功能清单.md / AP功能文档.md / AP适配luci-app-wifi-ac功能清单.md
- luasrc/controller/wifi-ap.lua
- files/usr/bin/ap_agent
- files/usr/sbin/wifi-ap-firmware-upload.sh
- files/etc/logrotate.d/ap_agent
- files/usr/sbin/wifi-ap-log-clean.sh
- luasrc/model/cbi/wifi-ap.lua
- luasrc/view/wifi-ap/index.htm
- htdocs/luci-static/resources/wifi-ap.js

---
