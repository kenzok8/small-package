## fakemesh简介

fakemesh是一种网络拓扑结构，由一个`控制器（AC）`和一个或多个`有线AP（Wired AP）`和`卫星（Agent）`组成。它是一种混合了`无线Mesh`和`AC+AP`两种组网模式的混合网络，其中，`有线AP`通过网线和`控制器（AC）`相连，而`卫星（Agent）`则通过无线STA方式接入，共同构成一个无线（包括有线）覆盖网络。

fakemesh的部署确实相对较为方便，只需要将节点设备连接到正确的网络，并设置节点设备的角色，Mesh ID等信息即可。因为fakemesh结合了无线Mesh和AC+AP两种组网模式，所以也可以很方便地进行混合组网，提高了网络的覆盖范围和可靠性。

目前[X-WRT](https://github.com/x-wrt/x-wrt)默认集成了fakemesh功能

## fakemesh 使用

### 组网成功后统一的访问设备的地址格式如下:

访问控制器的地址: `http://controller.fakemesh/`或者`http://ac.fakemesh/`

访问AP的地址: `http://{mac}.ap.fakemesh/` 或者 `http://N.ap.fakemesh/`

其中`{mac}`是AP的MAC地址，比如`{mac}=1122334455AB`，`N`是AP的自动编号，比如 N=1, N=2, N=3, ...

例子:
```
http://1.ap.fakemesh/
http://1122334455AB.ap.fakemesh/
```

### 故障处理:

AP离线3分钟左右进入故障模式，这个模式开启默认SSID，可以提供接入管理重新配置。
故障模式的默认SSID和密码是:
```
SSID: X-WRT_XXXX
PASSWD: 88888888
```

故障模式下AP的管理IP地址是DHCP的网关地址，比如电脑获取到`192.168.16.x`的IP，那么AP的管理IP就是`192.168.16.1`

## fakemesh 基本组成

组网由一个`控制器(controller)`和一个或者多个`AP`组成

AP包括: `卫星(Agent)`和`有线AP(Wired AP)`两种

**控制器(Controller)**:  作为AC和出口路由器，提供网络出口上网，统一管理下挂的卫星和有线AP，统一管理无线

**卫星(Agent)**:  通过Wi-Fi组网接入的AP

**有线AP(Wired AP)**:  通过网线组网接入的AP

## fakemesh 配置参数

### 1. Mesh ID

   这个参数是fakemesh网络组网的统一ID，控制器、卫星、有线AP都要设置相同的Mesh ID。

### 2. 密钥(Key)

   这是组网的统一密钥，组网加密需要，如果不需要加密可以留空白。

### 3. 带宽(Band)

   这是组网使用的无线频段，要设置相同，5G或者2G。

### 4. 角色(Role)

   可以是控制器、卫星、有线AP。

### 5. 同步配置(Sync Config)

   是否统一管理Wi-Fi配置等，Wi-Fi配置由控制器统一配置管理。

### 6. 访问 IP 地址(Access IP address)

   设置一个特定的IP地址给控制器，可以通过这个IP访问控制器的管理界面。

### 7. 关闭前传(Fronthaul Disabled)
   这个节点关闭前传无线信号，也就是不允许其他AP节点通过这个节点Wi-Fi接入。

### 8. 漫游组件(Band Steer Helper)
   目前可以选择[DAWN](https://github.com/fakemesh/dawn)或者[usteer](https://github.com/fakemesh/usteer)作为漫游辅助控件。

## 无线管理(Wireless Management)

   可以在控制器界面上统一管理无线，包括增删SSID，设置SSID的加密方式，频宽。

## 控制器(Controller)旁路部署

   需要注意的是，如果控制器不作为网关出口并且不提供DHCP服务，用户需要手动配置网络设置，包括设置控制器的LAN口IP地址、网关IP和DNS。此外，通常控制器的LAN口会默认启用DHCP客户端，从第三方网关获取IP和网关，如果需要使用静态IP，则需要保证控制器和第三方网关在同一个网段且可以相互通信。否则，就无法实现控制器与其他AP的同步配置。

## 网络拓扑展示规格 (Network Topology)

FakeMesh 提供了全网可视化网络拓扑功能（Web 路径：**Mesh 组网 -> 网络拓扑** / `admin/mesh/topology`），用于实时监测全网控制器、无线/有线卫星节点、多级级联节点以及所有接入终端的连接关系与链路质量。

### 1. 核心特性与架构机制

- **动态实时探测（零第三方依赖）**：
  - 不依赖 `usteer`、`DAWN` 或任何静态拓扑缓存文件。
  - 用户打开页面或前端定时轮询时，由控制器（AC）实时读取本机状态，并通过 HTTP/ubus 接口并发请求各在线节点的 `luci.fakemesh get_node_info` 接口，毫秒级汇聚全网最新状态。
- **对称上下级拓扑解析**：
  - **控制器（AC）**：自动探测上游 WAN 口出网网关（PPPoE / DHCP WAN IP）。
  - **卫星节点（Agent / Wired AP）**：自动探测上级母机节点（父节点 Hostname/IP）、回程类型（无线 5G/2.4G Mesh 或有线以太网）、回程 BSSID、信号强度（dBm）、双向协商物理速率（Mbps）、频段与信道。
  - **多级跳拓扑（Multi-hop Cascade）**：支持多跳级联链路（如 AC -> Agent 1 -> Agent 2），算法自动基于上游 BSSID/MAC 递归构建拓扑树，计算每个节点的级联层级（`hop_count`）并具备防环路检测机制。
- **跨节点终端冲突裁决与信息聚合**：
  - **智能打分归属**：若某终端设备漫游或在多个节点均有历史记录，算法结合各节点报告的空闲时间（`idle_time`）、Wi-Fi 信号强度、接入类型进行打分加权，精准将终端归属至当前最新活跃的节点。
  - **多 IP 与 IPv6 聚合**：收集并展示同一 MAC 终端名下的**全部 IPv4 地址**（支持单设备多 IP）及**全部 IPv6 地址**（来自内核 IPv6 邻居表）。
  - **主机名补全**：若分节点未获取到终端主机名，自动回退利用 AC 的 DHCP 主机名库或 NAT 用户名库补齐。
  - **骨干节点过滤**：自动识别并剔除所有 Mesh 路由节点自身的 MAC 与 IP，避免路由器被错误展示为终端设备。
- **支持接入类型识别**：
  - **无线终端**：展示 5G / 2.4G 频段、SSID、信号强度（dBm）、协商物理速率（PHY Rate）。
  - **有线终端**：展示接入端口（WAN / LAN1~LAN4）及端口协商速率（1000M / 2.5G）。
  - **VPN 客户端终端**：识别通过 VPN 拨号/加速接口（如 `natcapudp` 等虚拟网卡）接入的终端，并标注 VPN 标识。

### 2. 前端展示规格与交互设计

- **双视图自由切换**：
  - **🗺️ 微缩拓扑视图（Minimap View，默认）**：
    - 精简鸟瞰网络全貌，清晰展现各个节点之间的级联连接线、角色标签、在线状态、上级节点指标（如 `↑ 上级: X-WRT (192.168.16.1)`）、回程链路徽标及挂载设备计数。
    - **点击放大联动（Focused Node Inspector Panel）**：点击微缩图中的任意节点芯片，该节点显示 `[当前选中]` 蓝色高亮，下方看板即时放大呈现该节点的完整规格（角色、硬件型号、MAC、运行时间、上级节点快捷切换跳转）以及**该节点下挂载的所有终端卡片**。
  - **🌲 完整展开视图（Expanded View）**：
    - 级联树状全景平铺，直观展现所有节点和所有终端卡片，适合大屏全屏监控。
- **终端卡片展示规格**：
  - 设备图标（基于设备名智能推断手机、平板、笔记本、PC、电视、IoT 等）、设备名。
  - **多 IPv4 显示**：以等宽字体徽章直接罗列所有 IPv4 地址。
  - **IPv6 显示**：紫底徽章直接展示完整 IPv6 地址。
  - **实时网速与信号**：动态展示当前下行/上行即时速率（`↓ xx KB/s ↑ xx KB/s`）、无线信号质量。
  - **详情弹窗**：点击卡片可弹出模态框查看主 IP、多 IP 清单、IPv6 清单、MAC、接入方式、空闲时间、协商速率（RX/TX）以及累计下行/上行流量。
- **全网汇总状态栏 (Summary Bar)**：
  - 顶部实时统计 Mesh ID、回程链路模式（无线 Mesh / 有线 AP / 多跳级联）、组网节点数（在线节点）、全网接入终端总数、频段终端分布（5G / 2.4G / 有线 / VPN）以及全网聚合下行/上行即时吞吐率。
- **实时刷新与状态保持**：
  - 页面采用 5 秒无感轮询刷新机制（`poll.add(..., 5)`）。
  - 刷新过程中保留用户当前的微缩图选中节点、搜索关键字与筛选条件，界面平滑不闪烁。
- **实时检索与频段过滤**：
  - 支持按主机名、IPv4、IPv6、MAC 地址实时模糊检索。
  - 快速切换筛选：`全部终端` / `5G` / `2.4G` / `有线` / `VPN`。

### 3. 后端 RPCD 接口规格

#### (1) `luci.fakemesh get_topology`
由 Web 前端调用 AC 控制器，返回全网拓扑与终端汇总数据。

- **调用方式**：`ubus call luci.fakemesh get_topology`
- **返回结构**：
  ```json
  {
    "mesh_id": "mesh-x-wrt-natcap",
    "timestamp": 1791569719,
    "summary": {
      "node_count": 2,
      "online_agents": 1,
      "offline_agents": 0,
      "client_count": 11,
      "wifi_5g": 6,
      "wifi_2g": 2,
      "wired": 2,
      "vpn": 1,
      "total_rx_speed": 1650,
      "total_tx_speed": 1091,
      "max_hops": 1,
      "wireless_nodes": 1,
      "wired_nodes": 0
    },
    "nodes": [
      {
        "id": "ac",
        "role": "controller",
        "hostname": "X-WRT",
        "ip": "192.168.16.1",
        "mac": "B8:60:61:7D:E9:B9",
        "model": "CMCC RAX3000M",
        "uptime": 65756,
        "online": true,
        "hop_count": 0,
        "parent_name": "Internet (100.73.112.26)",
        "parent_ip": "100.73.112.26",
        "upstream": { "type": "root", "wan_ip": "100.73.112.26" },
        "downstream": { "total_count": 7, "wireless_count": 6, "wired_count": 0, "vpn_count": 1 }
      },
      {
        "id": "node_50DA9E569A10",
        "role": "agent",
        "hostname": "MESH-AGENT_50DA9E569A10",
        "ip": "192.168.16.188",
        "mac": "50:DA:9E:56:9A:10",
        "model": "Tenda BE6L Pro",
        "online": true,
        "hop_count": 1,
        "parent_id": "ac",
        "parent_name": "X-WRT (192.168.16.1)",
        "parent_ip": "192.168.16.1",
        "upstream": {
          "type": "wireless",
          "band": "5G",
          "signal": -46,
          "rx_bitrate": 2401.9,
          "tx_bitrate": 1921.5,
          "parent_bssid": "B8:60:61:7D:E9:BB"
        },
        "downstream": { "total_count": 4, "wireless_count": 2, "wired_count": 2, "vpn_count": 0 }
      }
    ],
    "clients": [
      {
        "mac": "70:1A:B8:C5:9D:D8",
        "hostname": "Cecilia-Laptop",
        "node_id": "ac",
        "ip": "192.168.16.197",
        "ips": ["192.168.16.197", "169.254.58.167"],
        "ip6": ["fe80::e2ac:2f0b:1f7a:fcd8"],
        "access_type": "wireless",
        "band": "5G",
        "ssid": "NATCAP_9D91",
        "signal": -62,
        "rx_speed": 196,
        "tx_speed": 519,
        "icon": "laptop"
      }
    ]
  }
  ```

#### (2) `luci.fakemesh get_node_info`
由控制器 AC 调用各个分节点，返回该节点本机的硬件规格、回程状态、有线口与挂载客户端。

- **调用方式**：`ubus call luci.fakemesh get_node_info`
- **权限支持**：已在 `/usr/share/rpcd/acl.d/luci-app-fakemesh.json` 中放行，支持局域网内 AC 跨机 RPC 请求。

