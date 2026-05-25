# luci-app-wifi-ac AC端功能对AP端配合需求清单

本清单梳理AC端（luci-app-wifi-ac）各功能模块对AP端的配合要求，供AP固件开发、三方适配参考。

---

## 1. 设备信息与状态上报

- AP端需定时或被动上报静态信息（MAC、IP、厂商、型号、固件版本）。
- 动态状态/性能数据（在线/离线、CPU、内存、客户端数、信号、Uptime等）需支持主动上报和AC端拉取。
- 心跳机制：AP端定时主动/被动上报，AC端可通过ubus/UDP/HTTP接口获取。
- 必须实现标准ubus接口：  
  `ubus call wifi.status '{"mac":"xx:xx:xx:xx:xx:xx"}'`  
  返回结构需标准化，参考：
  ```json
  {
    "mac": "xx:xx:xx:xx:xx:xx",
    "status": "online",
    "cpu": 23,
    "mem": 41,
    "clients_24g": 12,
    "clients_5g": 8,
    "ip": "192.168.1.2",
    "vendor": "Huawei",
    "model": "AP123",
    "firmware": "v1.0.2"
  }
  ```

## 2. 远程命令响应

- AP端需实现标准ubus接口，支持远程重启、升级、配置同步、模板应用、信道/功率/接入数设置等。
- 支持批量操作ACK、失败重试，所有命令返回 `{code, msg}` 结构。
- 示例命令：
  ```sh
  ubus call wifi.device '{"mac":"xx:xx:xx:xx:xx:xx","action":"reboot"}'
  ubus call wifi.device '{"mac":"xx:xx:xx:xx:xx:xx","action":"upgrade","url":"http://ac/firmware.bin"}'
  ```
- 推荐实现UDP命令监听与ACK机制，收到命令后及时回复ACK，AC端自动重试。

## 3. 自动发现与注册
实现下面AP端的相关功能，完善其他相关文件（包含lua/htm/js/css）内容（缺少文件可以按照目录规则创建）；
- 支持UDP广播发现、mDNS发现（需mDNS responder）、HTTP主动注册（适配NAT/跨网段）。
- 守护进程监听UDP/mDNS/HTTP，响应AC端发现请求或主动注册。
- 采集结果写入 `/tmp/wifi-ac/discovered_devices.json`、`mdns_devices.json`、`http_devices.json` 等标准文件。

## 4. 固件升级与断点续传
实现下面AP端的相关功能，完善其他相关文件（包含lua/htm/js/css）内容（缺少文件可以按照目录规则创建）；
- 支持固件包接收、校验、升级，分块传输、断点续传、失败回滚。
- 升级进度/状态通过ubus/UDP/HTTP上报。
- 推荐实现脚本如 `wifi-ap-firmware-upload.sh`，支持分块上传、断点续传。

## 5. 配置同步与模板应用
实现下面AP端的相关功能，完善其他相关文件（包含lua/htm/js/css）内容（缺少文件可以按照目录规则创建）；
- 能接收AC下发的配置模板（UCI/JSON），自动应用并反馈结果。
- 支持配置参数热加载（无需重启服务）。
- 支持 `ubus call wifi.device '{"mac":"...","action":"apply_template","tpl":...}'`。
- 本地运行日志、操作日志采集，结构标准化（含时间、命令、用户、结果）。
- 日志轮转与自动清理（logrotate/定时脚本）。
- 日志API需做权限校验，支持多条件筛选、导出。

## 7. 趋势数据采集与持久化
实现下面AP端的相关功能，完善其他相关文件（包含lua/htm/js/css）内容（缺少文件可以按照目录规则创建）；
- 定时采集负载、信号、客户端数等性能数据，持久化到sqlite3/json。
- 支持API/ubus接口查询历史趋势数据，结构标准化。
- 所有与AC通信接口建议增加Token和签名字段，防止伪造和非法控制。
- 支持IP白名单校验，敏感API强制HTTPS。
- 签名算法建议HMAC-SHA256，密钥安全存储。
- 角色/权限配置文件管理，日志API细粒度权限校验。

## 9. WebSocket/事件推送（可选）
实现下面AP端的相关功能，完善其他相关文件（包含lua/htm/js/css）内容（缺少文件可以按照目录规则创建）；

 mDNS响应与HTTP主动注册（实现提升跨网段适用性）
-- mDNS响应：调用 avahi-publish-service 注册AP信息，AC端可通过mDNS发现AP
-- HTTP主动注册：定期向AC的/api/ap_register接口POST自身信息，适配NAT/跨网段环境
-- 详见脚本mdns_announce和http_register函数
- 支持通过ubus事件或WebSocket主动推送操作进度、状态变更（如升级、重启、配置变更等）到AC端，实现实时状态同步。
- 关键事件（上线/离线、升级结果、异常告警等）建议主动推送。
- 支持多AC冗余注册，提升高可用性。
- 所有接口RESTful标准化，参数/返回结构统一（如 `{code,msg,data}`）。
- 支持跨网段AP发现AC（主动HTTP注册、mDNS等）。
- 三方AP适配时，建议保留接口和注释，便于后续扩展。

---

**参考：luci-app-wifi-ac wifi-ap-README.md、AP功能文档.md、wifi-ap_ubus_example.lua等。**
