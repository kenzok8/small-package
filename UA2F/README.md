# UA2F

[![CodeQL](https://github.com/Zxilly/UA2F/actions/workflows/codeql.yml/badge.svg)](https://github.com/Zxilly/UA2F/actions/workflows/codeql.yml)
[![Build OpenWRT Package](https://github.com/Zxilly/UA2F/actions/workflows/ci.yml/badge.svg)](https://github.com/Zxilly/UA2F/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/Zxilly/UA2F/graph/badge.svg?token=6PBFSZCDWP)](https://codecov.io/gh/Zxilly/UA2F)

参照 [博客文章](https://learningman.top/archives/304) 完成操作

如果遇到了任何问题，欢迎提出 Issues，但是更欢迎直接提交 Pull Request

> 由于新加入的 CONNMARK 影响，编译内核时需要添加 `NETFILTER_NETLINK_GLUE_CT` flag
 
> 可以在网页 [http://ua-check.stagoh.com](http://ua-check.stagoh.com) 上测试 UA2F 是否正常工作

## 快速开始

```bash
# 启用 UA2F
uci set ua2f.enabled.enabled=1

# 可选的防火墙配置选项
# 是否自动添加防火墙规则
uci set ua2f.firewall.handle_fw=1

# 是否尝试处理 443 端口的流量， 通常来说，流经 443 端口的流量是加密的，因此无需处理
uci set ua2f.firewall.handle_tls=1

# 是否处理微信的流量，微信的流量通常是加密的，因此无需处理。这一规则在启用 nftables 时无效
uci set ua2f.firewall.handle_mmtls=1

# 是否处理内网流量，如果你的路由器是在内网中，且你想要处理内网中的流量，那么请启用这一选项
uci set ua2f.firewall.handle_intranet=1

# 使用自定义 User-Agent
uci set ua2f.main.custom_ua="Test UA/1.0"

# 运行模式，默认 NFQUEUE；也可使用 REDIRECT 或 TPROXY
uci set ua2f.main.mode="TPROXY"

# REDIRECT/TPROXY 透明代理监听端口，默认 10010
uci set ua2f.main.listen_port="10010"

# NFQUEUE 模式 worker 数，默认 1；自动防火墙规则会同步使用 queue-balance
uci set ua2f.main.nfqueue_workers="1"

# REDIRECT/TPROXY 模式代理 worker 数，默认 0 表示自动
uci set ua2f.main.proxy_workers="0"

# 禁用 Conntrack 标记，这会降低性能，但是有助于和其他修改 Connmark 的软件共存
uci set ua2f.main.disable_connmark=1

# 应用配置
uci commit ua2f

# 开机自启
service ua2f enable

# 启动 UA2F
service ua2f start

# 读取日志
logread | grep UA2F
```

## 配置

UA2F 的 OpenWRT 配置位于 `/etc/config/ua2f`。修改后需要执行 `uci commit ua2f`，并通过 `service ua2f restart` 重新启动服务。启用自动防火墙规则时，init 脚本会按 `main.mode` 生成对应规则。

### enabled

| 选项 | 默认值 | 说明 |
| --- | --- | --- |
| `enabled` | `0` | 是否启用 UA2F 服务。 |

```bash
uci set ua2f.enabled.enabled=1
```

### main

| 选项 | 默认值 | 说明 |
| --- | --- | --- |
| `mode` | `NFQUEUE` | 运行模式，可选 `NFQUEUE`、`REDIRECT`、`TPROXY`。UCI 可以直接设置该值；命令行 `--mode` 会覆盖 UCI 配置。 |
| `listen_port` | `10010` | `REDIRECT`/`TPROXY` 模式的本地透明代理监听端口。`NFQUEUE` 模式不使用该端口。 |
| `nfqueue_workers` | `1` | `NFQUEUE` 模式的工作线程和队列数量，范围 `1`-`16`。启用自动防火墙规则时会生成对应的 queue-balance 规则。 |
| `proxy_workers` | `0` | `REDIRECT`/`TPROXY` 模式的代理 worker 数，范围 `0`-`16`。`0` 表示自动，当前最多使用 4 个 CPU。 |
| `custom_ua` | 空 | 自定义 User-Agent 替换内容。UA2F 不改变包长度，长度不足会补空格，过长会截断。 |
| `disable_connmark` | `0` | 禁用 Conntrack 标记和缓存。会降低性能，但可避免和其他修改 Connmark 的程序冲突。 |
| `max_http_sessions` | `0` | HTTP parser session 上限，`0` 表示不限制。 |
| `session_ttl` | `300` | HTTP session 空闲过期时间，单位秒。 |

```bash
uci set ua2f.main.mode='TPROXY'
uci set ua2f.main.listen_port='10010'
uci set ua2f.main.nfqueue_workers='1'
uci set ua2f.main.proxy_workers='0'
uci set ua2f.main.custom_ua='Test UA/1.0'
uci set ua2f.main.disable_connmark='0'
uci set ua2f.main.max_http_sessions='0'
uci set ua2f.main.session_ttl='300'
uci commit ua2f
service ua2f restart
```

模式选择：

- `NFQUEUE`：默认模式，保持原有行为，通过 netfilter queue 改写 TCP 包。
- `REDIRECT`：透明代理模式，防火墙将流量 REDIRECT 到本地监听端口，再由 UA2F 连接原始目标。
- `TPROXY`：透明代理模式，适合接管转发流量；需要策略路由把 `fwmark 0x1c9` 指向 `lo`。固定监听端口的 TPROXY 不处理本机 OUTPUT 流量，本机流量请使用 `REDIRECT` 或 `NFQUEUE`。

### firewall

| 选项 | 默认值 | 说明 |
| --- | --- | --- |
| `handle_fw` | `1` | 是否由 init 脚本自动安装防火墙规则。关闭后需要手动配置 netfilter。 |
| `handle_tls` | `0` | 是否处理 443 端口流量。通常 HTTPS 已加密，不需要处理。 |
| `handle_intranet` | `1` | 是否处理内网/保留地址流量。设为 `0` 时会绕过内网/保留地址。 |
| `handle_mmtls` | `0` | 是否处理微信 mmtls 流量。该规则仅在 iptables NFQUEUE 分支中生效，nftables 分支无效。 |

```bash
uci set ua2f.firewall.handle_fw='1'
uci set ua2f.firewall.handle_tls='0'
uci set ua2f.firewall.handle_intranet='1'
uci set ua2f.firewall.handle_mmtls='0'
uci commit ua2f
service ua2f restart
```

## 自定义 User-Agent

### 集成到二进制

`make menuconfig` 后，使用 option 设置

![image](https://github.com/Zxilly/UA2F/assets/31370133/09469f69-4481-4bd8-9ce3-7029df33838d)

`UA2F_CUSTOM_UA` 的值必须是一个字符串，且长度不超过 `(65535 + (MNL_SOCKET_BUFFER_SIZE / 2))` 字节。 `MNL_SOCKET_BUFFER_SIZE` 的值通常为 8192。

### 使用 uci 设置

```bash
uci set ua2f.main.custom_ua="Test UA/1.0"
uci commit ua2f
```

> UA2F 不会修改包的大小，因此即使自定义了 User-Agent， 运行时实际的 User-Agent 会是一个从 custom ua 中截取的长度与原始 User-Agent 相同的子串，长度不足时会在末尾补空格。

## 在非 OpenWRT 系统上运行

自 `v4.5.0` 起，UA2F 支持在非 OpenWRT 系统上运行，但是需要手动配置防火墙规则，将需要处理的流量转发到 `netfilter-queue` 的 10010 队列中。

编译时，需要添加 `-DUA2F_ENABLE_UCI=OFF` flag 至 CMake。

默认模式仍为 NFQUEUE。非 OpenWRT 环境也可以使用透明代理模式：

```bash
sudo ./build/ua2f --mode REDIRECT --listen-port 10010
sudo ./build/ua2f --mode TPROXY --listen-port 10010
```

REDIRECT/TPROXY 需要自行配置对应的 netfilter 规则。TPROXY 还需要 `fwmark 0x1c9` 指向本机 `lo` 的策略路由；UA2F 的出站连接会设置 `SO_MARK 0xc9`，防火墙规则应绕过该 mark 以避免回环。固定监听端口的 TPROXY 模式只适合接管 PREROUTING/转发流量，本机 OUTPUT 流量请使用 REDIRECT 或 NFQUEUE。

## Benchmark

测试对象为 UA2F 和 [UA3F](https://github.com/SunBK201/UA3F)。测试环境为 WSL2 x86_64 / `Linux 6.18.26.1-microsoft-standard-WSL2` / `16` cores / `go1.26.3 linux/amd64`，客户端在独立 network namespace 中通过 PREROUTING 透明代理访问 `10.250.0.1:18080` origin server。UA2F 使用 `RelWithDebInfo` 构建，UA3F 使用 `GLOBAL` rewrite mode 和 `FFF` User-Agent；两者均完成 User-Agent 改写。

| 响应 | 请求数 | 模式 | 工具 | Req/s | Mbps | Avg/P95 ms | CPU % | RSS MB | HWM MB |
| --- | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 KiB | 50000 | DIRECT | 原始流量 | 101023.33 | 1059.17 | 1.21 / 3.54 | - | - | - |
| 1 KiB | 50000 | REDIRECT | UA2F | 68544.50 | 718.65 | 1.78 / 4.23 | 207.00 | 2.47 | 2.93 |
| 1 KiB | 50000 | REDIRECT | [UA3F](https://github.com/SunBK201/UA3F) | 59661.38 | 625.52 | 2.07 / 4.92 | 427.18 | 43.43 | 47.40 |
|  |  |  | UA2F / UA3F | 1.15x | 1.15x | 0.86x / 0.86x | 0.48x | 0.06x | 0.06x |
| 1 KiB | 50000 | TPROXY | UA2F | 64939.07 | 680.85 | 1.89 / 4.79 | 206.51 | 2.53 | 2.96 |
| 1 KiB | 50000 | TPROXY | [UA3F](https://github.com/SunBK201/UA3F) | 64341.75 | 674.59 | 1.92 / 4.68 | 428.52 | 45.84 | 45.88 |
|  |  |  | UA2F / UA3F | 1.01x | 1.01x | 0.98x / 1.02x | 0.48x | 0.06x | 0.06x |
| 64 KiB | 100000 | DIRECT | 原始流量 | 92629.47 | 48777.77 | 1.33 / 4.02 | - | - | - |
| 64 KiB | 100000 | REDIRECT | UA2F | 61288.57 | 32273.96 | 2.05 / 5.04 | 256.19 | 2.47 | 3.05 |
| 64 KiB | 100000 | REDIRECT | [UA3F](https://github.com/SunBK201/UA3F) | 56559.67 | 29783.77 | 2.21 / 5.27 | 449.08 | 43.93 | 47.22 |
|  |  |  | UA2F / UA3F | 1.08x | 1.08x | 0.93x / 0.96x | 0.57x | 0.06x | 0.06x |
| 64 KiB | 100000 | TPROXY | UA2F | 62754.99 | 33046.16 | 1.98 / 5.03 | 245.37 | 2.54 | 3.05 |
| 64 KiB | 100000 | TPROXY | [UA3F](https://github.com/SunBK201/UA3F) | 56478.45 | 29741.00 | 2.19 / 5.32 | 436.58 | 43.69 | 48.98 |
|  |  |  | UA2F / UA3F | 1.11x | 1.11x | 0.90x / 0.95x | 0.56x | 0.06x | 0.06x |

### 复现实验

仓库内置 benchmark 脚本会自动构建 Go client/server，并生成 Markdown/JSON 报告。将 `--body-bytes` 改为 `1024` 可复现小响应测试。

```bash
sudo python3 scripts/benchmark.py \
  --ua2f ./build/ua2f \
  --ua3f ./ref/UA3F/ua3f \
  --ua2f-modes REDIRECT,TPROXY \
  --ua3f-modes REDIRECT,TPROXY \
  --requests 100000 \
  --warmup 10000 \
  --concurrency 128 \
  --body-bytes 65536
```

## TODO

- [ ] pthread 支持，由不同线程完成入队出队
- [ ] 重写正则匹配为 parser
- [ ] 以连接为单位维护 parser 状态

## License

[GPL-3.0](./LICENSE)
