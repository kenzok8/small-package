minisign for OpenWrt
===

[![Download][B]][2]  

简介
---

 本项目是 [minisign][1] 在 OpenWrt 上的移植  

特性
---

软件包只包含 [minisign][1] 的可执行文件, 可与 [luci-app-dnscrypt-proxy][3] 搭配使用  
可编译两种版本  

 - minisign

   ```
    /
   └── usr/
       └── bin/
           └── minisign      // 可执行文件
   ```

编译
---

 - 从 OpenWrt 的 [SDK][S] 编译

   ```bash
   # 以 ar71xx 平台为例
   tar xjf OpenWrt-SDK-ar71xx-for-linux-x86_64-gcc-4.8-linaro_uClibc-0.9.33.2.tar.bz2
   cd OpenWrt-SDK-ar71xx-*
   # 添加 feeds/libsodium
   git clone https://github.com/shadowsocks/openwrt-feeds.git package/libs
   # 获取 minisign Makefile
   git clone https://github.com/kenzok78/minisign.git package/minisign
   # 删除 libsodium/Makefile 中所有`CONFIGURE_ARGS`相关的行 [`--disable ssp` 及`CONFIG_LIBSODIUM_MINIMAL`](https://github.com/shadowsocks/openwrt-feeds/blob/master/packages/libsodium/Makefile#L54)
   # 其中包括： Libraries -> libsodium 非最小安装(.config/CONFIG_LIBSODIUM_MINIMAL=n)
   # 默认静态链接 `libsodium`，最终的二进制并不依賴： Utilities -> minisign(.config/CONFIG_minisign_STATIC_LINK=y; CONFIG_minisign_WITH_SODIUM=y)
   make menuconfig
   # 开始编译
   make package/minisign/compile V=99
   ```

配置
---

   软件包本身并不包含配置文件

  [1]: https://github.com/jedisct1/minisign
  [2]: https://github.com/jedisct1/minisign/releases/latest
  [B]: https://img.shields.io/github/release/jedisct1/minisign.svg
  [3]: https://github.com/peter-tank/luci-app-dnscrypt-proxy
  [S]: https://wiki.openwrt.org/doc/howto/obtain.firmware.sdk
