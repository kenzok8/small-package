OpenWrt/LEDE LuCI for MentoHUST
===

简介
---

本软件包是 MentoHUST 的 LuCI 控制界面,

软件包文件结构:
```
/
├── etc/
│   ├── config/
│   │   └── mentohust                               // UCI 配置文件
│   └── init.d/
│       └── mentohust                               // init 脚本
└── usr/
    └── lib/
        └── lua/
            └── luci/                               // LuCI 部分
                ├── controller/
                │   └── mentohust.lua               // LuCI 菜单配置
                ├── i18n/                           // LuCI 语言文件目录
                │   └── mentohust.zh-cn.lmo
                └── model/
                    └── cbi/
                        └── mentohust/
                            ├── general.lua         // LuCI 基本设置
                            └── log.lua             // LuCI 日志读取
```

依赖
---

软件包不显式依赖二进制文件 `mentohust`.
可通过编译安装 [MentoHUST-OpenWrt-ipk](https://github.com/KyleRicardo/MentoHUST-OpenWrt-ipk) 获得.  
只有当文件存在时, 相应的功能才可被使用, 并显示相应的 LuCI 设置界面.  
**请注意：mentohust 二进制文件必须支持所有参数。如：-u -p -n -i -m -g -s -o -t -e -r -a -d -b -y -f -c -w**  

 可执行文件  | 可选 | 功能        |
 ------------|------|-------------|
 `mentohust`  | 否   | 进行802.11x验证

注: 可执行文件需要在 `$PATH` 环境变量所表示的搜索路径中, 可被正常调用，否则不会出现LUCI界面.

配置
---

软件包的配置文件路径: `/etc/config/mentohust`  
此文件为 UCI 配置文件, 配置方式可参考 [OpenWrt Wiki][uci]  

编译
---

从 OpenWrt/LEDE 的 [SDK][openwrt-sdk] 编译  
```bash
# 解压下载好的 SDK
tar xjf lede-sdk-17.01.4-ramips-mt7620_gcc-5.4.0_musl-1.1.16.Linux-x86_64.tar.bz2
cd lede-sdk-*
# Clone 项目
git clone https://github.com/BoringCat/luci-app-mentohust.git package/luci-app-mentohust
# 编译 po2lmo (如果有po2lmo可跳过)
git clone https://github.com/openwrt-dev/po2lmo.git
pushd po2lmo
make && sudo make install
popd
# 选择要编译的包 LuCI -> 3. Applications
make menuconfig
# 开始编译
make package/luci-app-mentohust/compile V=99
```
 [openwrt-sdk]: https://wiki.openwrt.org/doc/howto/obtain.firmware.sdk
 [uci]: https://wiki.openwrt.org/doc/uci
