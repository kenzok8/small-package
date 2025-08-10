![hello](https://views.whatilearened.today/views/github/sirpdboy/deplives.svg) [![](https://img.shields.io/badge/TG群-点击加入-FFFFFF.svg)](https://t.me/joinchat/AAAAAEpRF88NfOK5vBXGBQ)

<h1 align="center">
  <br>luci-app-eqosplus<br>
</h1>

  <p align="center">

  <a target="_blank" href="https://github.com/sirpdboy/luci-app-eqosplus/releases">
    <img src="https://img.shields.io/github/release/sirpdboy/luci-app-eqosplus.svg?style=flat-square&label=luci-app-eqosplus&colorB=green">
  </a>
</p>

[中文] | [English](README.md) 

![screenshots](https://raw.githubusercontent.com/sirpdboy/openwrt/master/doc/说明1.jpg)

请 **认真阅读完毕** 本页面，本页面包含注意事项和如何使用。

## 功能说明：

### 定时限速1.2.2版
#### 2023.7.19 定时限速1.2.2：增加更多日期：工作日和休息日，自定义日期1，2，3中间用逗号分隔;加入MAC地址限速，从此不用担心IPV6和IPV4的限速问题。

### 定时限速1.0版
#### 2022.12.24 定时限速在eqos的加强版，加入定时限制等功能。

## 编译使用方法 [![](https://img.shields.io/badge/-编译使用方法-F5F5F5.svg)](#编译使用方法-)

将luci-app-eqosplus添加至 LEDE/OpenWRT 源码的方法。

### 下载源码方法一：
编辑源码文件夹根目录feeds.conf.default并加入如下内容:

```Brach
    # feeds获取源码：
    src-git eqosplus  https://github.com/sirpdboy/luci-app-eqosplus
 ``` 
  ```Brach
   # 更新feeds，并安装主题：
    scripts/feeds update eqosplus
	scripts/feeds install luci-app-eqosplus
 ``` 	

### 下载源码方法：
 ```Brach
    # 下载源码
    git clone https://github.com/sirpdboy/luci-app-eqosplus package/luci-app-eqosplus
    make menuconfig
 ``` 
### 配置菜单
 ```Brach
    make menuconfig
	# 找到 LuCI -> Applications, 选择 luci-app-eqosplus, 保存后退出。
 ``` 
### 编译
 ```Brach 
    # 编译固件
    make package/luci-app-eqosplus/compile V=s
 ```

## 说明 [![](https://img.shields.io/badge/-说明-F5F5F5.svg)](#说明-)

源码来源：https://github.com/sirpdboy/luci-app-eqosplus


- 你可以随意使用其中的源码，但请注明出处。

![screenshots](https://raw.githubusercontent.com/sirpdboy/openwrt/master/doc/说明2.jpg)

## 界面

![screenshots](https://raw.githubusercontent.com/sirpdboy/openwrt/master/doc/eqosplus.png)

![screenshots](https://raw.githubusercontent.com/sirpdboy/openwrt/master/doc/eqosplus2.png)

# My other project

- 路由安全看门狗 ：https://github.com/sirpdboy/luci-app-watchdog
- 网络速度测试 ：https://github.com/sirpdboy/luci-app-netspeedtest
- 计划任务插件（原定时设置） : https://github.com/sirpdboy/luci-app-taskplan
- 关机功能插件 : https://github.com/sirpdboy/luci-app-poweroffdevice
- opentopd主题 : https://github.com/sirpdboy/luci-theme-opentopd
- kucat酷猫主题: https://github.com/sirpdboy/luci-theme-kucat
- kucat酷猫主题设置工具: https://github.com/sirpdboy/luci-app-kucat-config
- NFT版上网时间控制插件: https://github.com/sirpdboy/luci-app-timecontrol
- 家长控制: https://github.com/sirpdboy/luci-theme-parentcontrol
- 定时限速: https://github.com/sirpdboy/luci-app-eqosplus
- 系统高级设置 : https://github.com/sirpdboy/luci-app-advanced
- ddns-go动态域名: https://github.com/sirpdboy/luci-app-ddns-go
- 进阶设置（系统高级设置+主题设置kucat/agron/opentopd）: https://github.com/sirpdboy/luci-app-advancedplus
- 网络设置向导: https://github.com/sirpdboy/luci-app-netwizard
- 一键分区扩容: https://github.com/sirpdboy/luci-app-partexp
- lukcy大吉: https://github.com/sirpdboy/luci-app-lukcy

## 捐助

![screenshots](https://raw.githubusercontent.com/sirpdboy/openwrt/master/doc/说明3.jpg)

|     <img src="https://img.shields.io/badge/-支付宝-F5F5F5.svg" href="#赞助支持本项目-" height="25" alt="图飞了"/>  |  <img src="https://img.shields.io/badge/-微信-F5F5F5.svg" height="25" alt="图飞了" href="#赞助支持本项目-"/>  | 
| :-----------------: | :-------------: |
|![xm1](https://raw.githubusercontent.com/sirpdboy/openwrt/master/doc/支付宝.png) | ![xm1](https://raw.githubusercontent.com/sirpdboy/openwrt/master/doc/微信.png) |

<a href="#readme">
    <img src="https://img.shields.io/badge/-返回顶部-orange.svg" alt="图飞了" title="返回顶部" align="right"/>
</a>

![](https://visitor-badge-deno.deno.dev/sirpdboy.sirpdboy.svg)  [![](https://img.shields.io/badge/TG群-点击加入-FFFFFF.svg)](https://t.me/joinchat/AAAAAEpRF88NfOK5vBXGBQ)

