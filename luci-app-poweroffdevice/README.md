[![若部分图片无法正常显示，请挂上机场浏览或点这里到末尾看修复教程](https://visitor-badge.glitch.me/badge?page_id=sirpdboy-visitor-badge)](#解决-github-网页上图片显示失败的问题) [![](https://img.shields.io/badge/TG群-点击加入-FFFFFF.svg)](https://t.me/joinchat/AAAAAEpRF88NfOK5vBXGBQ)
<a href="#readme">
    <img src="https://img.vim-cn.com/69/df015dc73fc71da07c3264766e8032ac042fed.png" alt="图飞了😂" title="poweroffdevice" align="right" height="180" />
</a>

欢迎来到sirpdboy的源码仓库！
=
Welcome to sirpdboy's  git source of packages
-
[poweroffdevice 设备关机功能](luci-app-poweroffdevice)
==========================================

[![](https://img.shields.io/badge/-目录:-696969.svg)](#readme) [![](https://img.shields.io/badge/-使用说明-F5F5F5.svg)](#使用说明-) [![](https://img.shields.io/badge/-说明-F5F5F5.svg)](#说明-) [![](https://img.shields.io/badge/-捐助-F5F5F5.svg)](#捐助-) 

请 **认真阅读完毕** 本页面，本页面包含注意事项和如何使用。

poweroffdevice是一款基于OPNEWRT编译的关机源码插件。
-----------------------------------------

## 写在前面：
----------------------------------
   -这个关机功能最早使用者是KOOLSHARE的固件。苦于OPENWRT中没有关机补丁，有感于前辈们的付出，苦思2020年4月动手在OPENWRT上首次使用此插件，此源码源于官方源码重启的源码修改而来.
之前一直有朋友在问，怎么使用关机插件，关机插件是有二种使用方式。一种是下载插件编译，这相对来说占用资源多一点，另一种就是在系统的源码上修改。

## 使用说明 [![](https://img.shields.io/badge/-使用说明-F5F5F5.svg)](#使用说明-) 

将poweroffdevice关机功能 添加至 LEDE/OpenWRT 源码的二种方法。

## 使用关机功能方法一：
标准方法使用关机插件。

 ```Brach
    # 下载源码
    
    git clone https://github.com/sirpdboy/luci-app-poweroffdevice package/luci-app-poweroffdevice
    
    make menuconfig
 ``` 
 ```Brach
    # 配置菜单
    make menuconfig
	# 找到 LuCI -> Applications, 选择 luci-app-poweroffdevice, 保存后退出。
 ``` 
 ```Brach 
    # 编译固件
    make package/luci-app-poweroffdevice/{clean,compile} V=s
 ```
## 使用关机功能方法二【推荐此方法】：
系统的源码上修改，集成到系统源码菜单中，不需要另外选择和设置即可使用关机功能
 ```Brach 
    #在编译前,运行如下二条命令，集成到系统源码菜单中，不需要另外选择和设置即可使用关机功能。
	cd openwrt #进入源码目录
    curl -fsSL  https://raw.githubusercontent.com/sirpdboy/other/master/patch/poweroff/poweroff.htm > ./feeds/luci/modules/luci-mod-admin-full/luasrc/view/admin_system/poweroff.htm 
    curl -fsSL  https://raw.githubusercontent.com/sirpdboy/other/master/patch/poweroff/system.lua > ./feeds/luci/modules/luci-mod-admin-full/luasrc/controller/admin/system.lua

 ```


## 说明 [![](https://img.shields.io/badge/-说明-F5F5F5.svg)](#说明-)

源码来源：https://github.com/sirpdboy/luci-app-poweroffdevice

### 你可以随意使用其中的源码，但请注明出处。


你可以随意使用其中的源码，但请注明出处。
============================


# My other project

网络速度测试 ：https://github.com/sirpdboy/NetSpeedTest

定时设置插件 : https://github.com/sirpdboy/luci-app-autotimeset

关机功能插件 : https://github.com/sirpdboy/luci-app-poweroffdevice

opentopd主题 : https://github.com/sirpdboy/luci-theme-opentopd

opentoks 主题: https://github.com/sirpdboy/luci-theme-opentoks [仿KOOLSAHRE主题]

btmob 主题: https://github.com/sirpdboy/luci-theme-btmob

系统高级设置 : https://github.com/sirpdboy/luci-app-advanced

ddns-go动态域名: https://github.com/sirpdboy/luci-app-ddns-go


## 捐助

-如果你觉得此项目对你有帮助，请捐助我们，以使项目能持续发展，更加完善。··请作者喝杯咖啡~~~**
-你们的支持就是我的动力！**

|     <img src="https://img.shields.io/badge/-支付宝-F5F5F5.svg" href="#赞助支持本项目-" height="25" alt="图飞了😂"/>  |  <img src="https://img.shields.io/badge/-微信-F5F5F5.svg" height="25" alt="图飞了😂" href="#赞助支持本项目-"/>  | 
| :-----------------: | :-------------: |
|![xm1](https://raw.githubusercontent.com/sirpdboy/openwrt/master/doc/支付宝.png) | ![xm1](https://raw.githubusercontent.com/sirpdboy/openwrt/master/doc/微信.png) |

<a href="#readme">
    <img src="https://img.shields.io/badge/-返回顶部-orange.svg" alt="图飞了😂" title="返回顶部" align="right"/>
</a>

