### 支持版本

OpenWrt 19.07 及以上
### 使用

添加软件源


```
sh -c "$(curl https://fastly.jsdelivr.net/gh/EkkoG/openwrt-dist@master/add-feed.sh)" -- luci
```

更新软件源并安装

```
opkg update
opkg install luci-app-natmap
```
