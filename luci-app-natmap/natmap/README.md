### 新功能

1. 内置两种消息通知方式，Telegram Bot 和 PushPlus，可以为任何每一个打洞单独配置, PushPlus 支持推送到微信且不需要翻墙
2. 内置多种配置模式，常用功能无需写脚本就能使用，详见内置模式

### 内置模式

#### qBittorrent

打洞成功后，自动修改 qBittorrent 的端口号，并配置转发（可选）

需要配置 qBittorrent 地址、账号、密码用于修改端口
需要配置 qBittorrent 使用网卡的 IP 用于配置转发，端口填 0，会转发到修改后的端口

#### Transmission

打洞成功后，自动修改 Transmission 的端口号，并配置转发（可选）

需要配置 Transmission 地址、账号、密码用于修改端口
需要配置 Transmission 使用网卡的 IP 用于配置转发，端口填 0，会转发到修改后的端口

#### Emby

配合 Emby Connect 使用时，用户登录账号后，会从服务器获取最新的连接地址信息，此模式就是用于配置这些信息的

需要配置 Emby 地址和 API Key 用于修改连接地址信息

此模式必须配置转发

默认不更新「外部域」，如果有配置 DDNS，将 DDNS 域名填入外部域后将不需要再次修改

若没有域名，需要将 IP 填入外部域，可以勾选 「Update host with IP」

若对外提供的是 HTTPS 服务，需要勾选 「Update HTTPS Port」


#### Cloudflare Origin Rules

Cloudflare Origin Rules 可以设置回源端口，配合 DDNS 使用时，可以将 DDNS 域名指向 Cloudflare，然后将回源端口设置为打洞后的端口，这样就可以通过 Cloudflare 的 CDN 加速访问了

需要配置 Cloudflare 的 API Key，邮箱 和 Zone ID，Zone ID 可以在 Cloudflare 的域名首页找到

API Key 请访问 https://dash.cloudflare.com/profile/api-tokens 复制 Global API Key

需要先在 Cloudflare 后台的 Rules - Origin Rules 下添加一个 Origin Rules，然后将 Origin Rules 的 Name 填入配置中

Name 请保持唯一，否则会出现奇怪的问题


### 使用

添加软件源

```
curl -fsSL https://github.com/ekkog/openwrt-dist/raw/master/add-feed.sh | sh 
```

当前环境访问 GitHub 有问题时，可以使用 GitHub 镜像

```
curl -fsSL https://ghproxy.com/https://github.com/EkkoG/openwrt-dist/blob/master/add-feed.sh | sh
```

更新软件源并安装

```
opkg update
opkg install natmap
```
