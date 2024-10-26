# luci-app-suselogin

适用于 [四川轻化工大学](http://www.suse.edu.cn/) [锐捷网络](http://www.ruijie.com.cn/) Web 网络认证系统，可以自动连接网络，也可以通过设定的时间检测网络连接状态并自动重连。

![插件主页截图](https://i.loli.net/2020/12/13/fgeaURwjbLT1odS.png)

![插件运行日志截图](https://i.loli.net/2020/12/13/XQ7q1FagVTm6LrO.png)

## 可用固件

这是我编译好的，Newifi D2 路由器可用的固件 https://github.com/blackyau/make_lede/releases/tag/suse 。它内置了这个自动拨号的插件，还内置了 [Zxilly/UA2F](https://github.com/Zxilly/UA2F) 或 [CHN-beta/xmurp-ua](https://github.com/CHN-beta/xmurp-ua) 和 [CHN-beta/rkp-ipid](https://github.com/CHN-beta/rkp-ipid) 还有 NTP-Server TTL 之类的多种抗检测方案，可以防止多设备被封。目前看来 UA2F 要更胜一筹。

## 快速开始

前往 Releases 下载已编译好的 ipk https://github.com/blackyau/luci-app-suselogin/releases/latest

在 OpenWrt - 系统 - 文件传输 选择该 ipk 点击上传，然后在下方安装。

![filetransfer](./filetransfer.jpg)

安装完毕后在 网络 - SUSE Login 点击**启用**并填入**用户名**和**密码**选择你的**运营商**后点击右下方的**保存&应用**，查看日志当提示**登录成功**时说明已登录成功。

如果提示缺少依赖，那么还需要安装 `curl`，请使用 Xshell 之类的软件连接到路由器，然后执行以下命令安装 `curl` 。

```shell
opkg update
opkg install curl
```

## 单独编译IPK

先准备好环境 Ubuntu 18 LTS x64 ，安装编译环境的依赖

```shell
sudo apt-get update
sudo apt-get -y install build-essential asciidoc binutils bzip2 gawk gettext git libncurses5-dev libz-dev patch python3 python2.7 unzip zlib1g-dev lib32gcc1 libc6-dev-i386 subversion flex uglifyjs git-core gcc-multilib p7zip p7zip-full msmtp libssl-dev texinfo libglib2.0-dev xmlto qemu-utils upx libelf-dev autoconf automake libtool autopoint device-tree-compiler g++-multilib antlr3 gperf wget curl swig rsync
```

下载 `lede`/`OpenWrt` 和 `luci-app-suselogin` 源码并进入编译配置菜单

```shell
git clone https://github.com/coolsnowwolf/lede
cd lede
./scripts/feeds update -a
./scripts/feeds install -a
git clone https://github.com/blackyau/luci-app-suselogin.git package/luci-app-suselogin
make menuconfig
```

在 make menuconfig 里面选好自己的机型，然后将 LuCI ---> Applications ---> luci-app-suselogin

选中，并将前面的复选框变为 `<M>` 再保存编译配置

接下来开始单独编译该插件的 IPK

```shell
make package/luci-app-suselogin/compile -j1 V=s
```

编译后的 ipk 在 `bin/packages/` 目录内，同时也会有 `curl` 之类的依赖，如果你的固件已经装好了依赖就只需要拷贝安装 `luci-app-suselogin_X.X-X_all.ipk` 即可。

## 固件集成插件

请查看 https://github.com/coolsnowwolf/lede 你必须要先知道如何编译正常的固件，才会在编译的过程中加入该扩展。

```shell
cd lede/package  # 进入 OpenWrt 源码的 package 目录
git clone https://github.com/blackyau/luci-app-suselogin.git  # 下载插件源码
cd ..  # 返回 OpenWrt 源码主目录
make menuconfig  # 进入编译设置菜单
```

LuCI ---> Applications ---> luci-app-suselogin

将其选中，使得复选框变为 `<*>` 再保存编译设置，随后正常编译即可。固件会自带 `luci-app-suselogin`

```shell
make -j8 download
make -j$(($(nproc) + 1)) V=s
```

## 实现细节

当插件设置为启用后，每隔指定的间隔时间，会检测登录状态，如果未连接到互联网则会尝试登录，同时还会检测当前在线设备数量并保存，如果这次检测的在线数量比上一次的多，就会自动下线并重新登录。

发送登录请求返回数据: `/tmp/log/suselogin/login.log`

完整日志: `/tmp/log/suselogin/suselogin.log`


## TODO

- [X] 函数式编程
- [X] curl指定超时
- [ ] 主脚本配置使用参数传入

## 参考

- [GitHub@coolsnowwolf - Lean’s OpenWrt source](https://github.com/coolsnowwolf/lede)
- [博客园@大魔王mAysWINd - 开发OpenWrt路由器上LuCI的模块](https://www.cnblogs.com/mayswind/p/3468124.html)
- [Github@OpenWrt - luci WIKI](https://github.com/openwrt/luci/wiki/CBI)
- [目录@陈浩南 - 在厦大宿舍安装路由器](https://catalog.chn.moe/%E6%95%99%E7%A8%8B/OpenWrt/%E5%9C%A8%E5%8E%A6%E5%A4%A7%E5%AE%BF%E8%88%8D%E5%AE%89%E8%A3%85%E8%B7%AF%E7%94%B1%E5%99%A8/)
- [OpenWrt@Documentation - System configuration /etc/config/system](https://openwrt.org/docs/guide-user/base-system/system_configuration)
- [OpenWrt@Documentation - Init Scripts](https://openwrt.org/docs/techref/initscripts)
- [OpenWrt@Documentation - NTP client / NTP server](https://openwrt.org/docs/guide-user/services/ntp/client-server)
- [askubuntu@Greg Hanis - How to remove or delete single cron job using linux command?](https://askubuntu.com/questions/408611)
- [stackoverflow@dchakarov - Create timestamp variable in bash script](https://stackoverflow.com/questions/17066250)
- [stackoverflow@Joe Casadonte - How do I create a crontab through a script](https://stackoverflow.com/questions/4880290)
- [stackoverflow@user0000001 - Search for a cronjob with crontab -l](https://stackoverflow.com/questions/14450866)
- [知乎@Maxwell - 如何优雅地创建重定向路径中不存在的父目录](https://zhuanlan.zhihu.com/p/61890472)
- [博客园@程默 - linux shell 时间运算以及时间差计算方法](https://www.cnblogs.com/chengmo/archive/2010/07/13/1776473.html)
- [橙子_MAX的个人博客 - 【教程笔记】用OpenWRT单独编译ipk插件](https://www.maxlicheng.com/openwrt/42.html)
- [Xavier Wang - 校园网禁止多终端共享上网解决方案](https://www.xavier.wang/post/45-suck-shit-lan/)

## License

Copyright 2020 BlackYau <blackyau426@gmail.com>

GNU General Public License v3.0
