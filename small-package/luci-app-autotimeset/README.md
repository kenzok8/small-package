[![若部分图片无法正常显示，请挂上机场浏览或点这里到末尾看修复教程](https://visitor-badge.glitch.me/badge?page_id=sirpdboy-visitor-badge)](#解决-github-网页上图片显示失败的问题) [![](https://img.shields.io/badge/TG群-点击加入-FFFFFF.svg)](https://t.me/joinchat/AAAAAEpRF88NfOK5vBXGBQ)

[autotimeset  定时设置插件](https://github.com/sirpdboy/luci-app-autotimeset)
======================
请 **认真阅读完毕** 本页面，本页面包含注意事项和如何使用。

## 功能说明：

### 定时设置1.4版
#### 2021.2.7 新增功能定时重启网络。现包括：定时重启、定时关机、定时重启网络，各功能可一起使用。

### 定时设置1.3版
#### 2020.10.6 原来重定关机正式改名为定时设置，实现定时重启和定时关机功能二合一。

### 定时关机1.1版
#### 2020.7.19  定时关机功能，彻底解决需要保存二次才生效的问题。

### 定时关机1.0版
#### 2019.2.24 定时关机功能借鉴前辈们的开源代码首发。

## 编译使用方法 [![](https://img.shields.io/badge/-编译使用方法-F5F5F5.svg)](#编译使用方法-)

将luci-app-autotimeset添加至 LEDE/OpenWRT 源码的方法。

### 下载源码方法一：
编辑源码文件夹根目录feeds.conf.default并加入如下内容:

```Brach
    # feeds获取源码：
    src-git autotimeset  https://github.com/sirpdboy/luci-app-autotimeset
 ``` 
  ```Brach
   # 更新feeds，并安装主题：
    scripts/feeds update autotimeset
	scripts/feeds install luci-app-autotimeset
 ``` 	

### 下载源码方法二：
 ```Brach
    # 下载源码
    git clone https://github.com/sirpdboy/luci-app-autotimeset package/luci-app-autotimeset
    make menuconfig
 ``` 
### 配置菜单
 ```Brach
    make menuconfig
	# 找到 LuCI -> Applications, 选择 luci-app-autotimeset, 保存后退出。
 ``` 
### 编译
 ```Brach 
    # 编译固件
    make package/luci-app-autotimeset/compile V=s
 ```

## 说明 [![](https://img.shields.io/badge/-说明-F5F5F5.svg)](#说明-)

源码来源：https://github.com/sirpdboy/luci-app-autotimeset

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

## 捐助 [![](https://img.shields.io/badge/-捐助-F5F5F5.svg)](#捐助-) 

**如果你觉得此项目对你有帮助，请捐助我们，以使项目能持续发展，更加完善。··请作者喝杯咖啡~~~**

**你们的支持就是我的动力！**

### 捐助方式

|     <img src="https://img.shields.io/badge/-支付宝-F5F5F5.svg" href="#赞助支持本项目-" height="25" alt="图飞了😂"/>  |  <img src="https://img.shields.io/badge/-微信-F5F5F5.svg" height="25" alt="图飞了😂" href="#赞助支持本项目-"/>  | 
| :-----------------: | :-------------: |
|<img src="https://img.vim-cn.com/fd/8e2793362ac3510094961b04407beec569b2b4.png" width="150" height="150" alt="图飞了😂" href="#赞助支持本项目-"/>|<img src="https://img.vim-cn.com/c7/675730a88accebf37a97d9e84e33529322b6e9.png" width="150" height="150" alt="图飞了😂" href="#赞助支持本项目-"/>|

<a href="#readme">
    <img src="https://img.shields.io/badge/-返回顶部-orange.svg" alt="图飞了😂" title="返回顶部" align="right"/>
</a>

###### [解决 Github 网页上图片显示失败的问题](https://blog.csdn.net/qq_38232598/article/details/91346392)

[![](https://img.shields.io/badge/TG群-点击加入-FFFFFF.svg)](https://t.me/joinchat/AAAAAEpRF88NfOK5vBXGBQ)

