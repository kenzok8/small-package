# luci-app-easytier

依赖`kmod-tun`需要先在系统软件包里安装好
### 快速开始

1. 右上角Fork克隆本项目
2. 修改 `.github/workflows/build.yml`，在 `jobs.build.strategy` 修改 arch 和 sdk
  - 建议 arch 只保留需要的选项，加速编译
  - sdk 可根据需要填写，其中`SNAPSHOT`后缀的是apk安装包，`openwrt-22.03`的是ipk安装包（也可以根据自己的路由 OpenWRT 版本修改）
3. 到 actions 手动触发自动编译流程，注意需要填写 release，否则只编译不发布，参考下图：
 <img width="2727" height="866" alt="image" src="https://github.com/user-attachments/assets/24a55d1c-7937-4cef-87f8-cd8778b5f009" />

### 安装方法
```bash
#先上传到openwrt的/tmp/tmp目录里安装
opkg install /tmp/tmp/luci-app-easytier_all.ipk

#卸载
opkg remove luci-app-easytier

#更新版本需要先卸载再安装新的ipk然后去管理界面关闭插件 修改参数后重新点击应用并保存
#安装后openwrt管理界面里不显示easytier 请注销登录或关闭窗口重新打开  
```

```bash
#如果是新版openwrt使用的是apk包管理器 出现无法安装apk的可以尝试使用忽略证书验证
apk add --allow-untrusted /tmp/tmp/luci-app-easytier.apk
```

此luci-app-easytier不包含二进制程序，需要自行在openwrt管理界面里的easytier插件界面里上传二进制程序

### 编译方法
```bash
#下载openwrt编译sdk到opt目录（不区分架构）
wget -qO /opt/sdk.tar.xz https://downloads.openwrt.org/releases/22.03.5/targets/rockchip/armv8/openwrt-sdk-22.03.5-rockchip-armv8_gcc-11.2.0_musl.Linux-x86_64.tar.xz
tar -xJf /opt/sdk.tar.xz -C /opt

cd /opt/openwrt-sdk*/package
#克隆luci-app-easytier到sdk的package目录里
git clone https://github.com/EasyTier/luci-app-easytier.git /opt/luci-app-easytier
cp -R /opt/luci-app-easytier/luci-app-easytier .

cd /opt/openwrt-sdk*
#升级脚本创建模板
./scripts/feeds update -a
make defconfig

#开始编译
make package/luci-app-easytier/compile V=s -j1

#编译完成后在/opt/openwrt-sdk*/bin/packages/aarch64_generic/base目录里
cd /opt/openwrt-sdk*/bin/packages/aarch64_generic/base
#移动到/opt目录里
mv *.ipk /opt/luci-app-easytier_all.ipk
```

> 如果在 状态-系统日志里 出现下图日志内容可以使用以下命令解决

```
Fri Feb  7 11:13:30 2025 daemon.err uhttpd[3381]: luci.util.pcdata() has been replaced by luci.xml.pcdata() - Please update your code.
Fri Feb  7 11:13:30 2025 daemon.err uhttpd[3381]: luci.util.pcdata() has been replaced by luci.xml.pcdata() - Please update your code.
Fri Feb  7 11:13:30 2025 daemon.err uhttpd[3381]: luci.util.pcdata() has been replaced by luci.xml.pcdata() - Please update your code.
Fri Feb  7 11:13:30 2025 daemon.err uhttpd[3381]: luci.util.pcdata() has been replaced by luci.xml.pcdata() - Please update your code.
Fri Feb  7 11:13:30 2025 daemon.err uhttpd[3381]: luci.util.pcdata() has been replaced by luci.xml.pcdata() - Please update your code.
```

```
sed -i 's/util/xml/g' /usr/lib/lua/luci/model/cbi/easytier.lua
```

