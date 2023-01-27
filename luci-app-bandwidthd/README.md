# luci-app-bandwidthd
为OpenWRT上bandwidthd开发的luci配置页面，用于统计局域网各个IP的流量状况并绘图

简介
---
为编译[此固件][N]所需依赖包而写

可以方便的统计某个网卡上所有客户端的流量并绘图，还可以对不同类型的流量进行分类。

使用方法
---
1、首先使用ifconfig命令查看内网的地址和该地之对应的网卡，这里我配置的无线网段为192.168.2.1/24,网卡是eth0.2。

2、打开luci配置页面，在[被监控网卡]中填入第一步看到的网卡，被监控网段填入第一步观察到的网段

3、使用局域网的设备上网、看视频等等持续5分钟左右，打开192.168.2.1/bandwidthd查看（IP地址根据你的路由器地址确定），就可以看到每个设备的流量和图形统计结果了

![demo](https://github.com/AlexZhuo/BreakwallOpenWrt/raw/master/screenshots/bandwidthd1.png)


编译
---

 - 从 OpenWrt 的 [SDK][S] 编译  

   ```bash
   # 以 ar71xx 平台为例
   tar xjf OpenWrt-SDK-ar71xx-for-linux-x86_64-gcc-4.8-linaro_uClibc-0.9.33.2.tar.bz2
   cd OpenWrt-SDK-ar71xx-*
   # 获取 Makefile
   git clone https://github.com/AlexZhuo/luci-app-bandwidthd.git package/luci-app-bandwidthd
   # 选择要编译的包 Luci -> Network -> luci-app-bandwidthd
   make menuconfig
   # 开始编译
   make package/luci-app-bandwidthd/compile V=99
   ```


[N]: http://www.right.com.cn/forum/thread-205639-1-1.html
[S]: http://wiki.openwrt.org/doc/howto/obtain.firmware.sdk
