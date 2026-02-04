![kenzo github stats](https://github-readme-stats.vercel.app/api?username=kenzok8&show_icons=true&theme=merko)
<div align="center">
<h1 align="center">同步上游分支代码</h1>
<img src="https://img.shields.io/github/issues/kenzok8/small-package?color=green">
<img src="https://img.shields.io/github/stars/kenzok8/small-package?color=yellow">
<img src="https://img.shields.io/github/forks/kenzok8/small-package?color=orange">
<img src="https://img.shields.io/github/license/kenzok8/small-package?color=ff69b4">
<img src="https://img.shields.io/github/languages/code-size/kenzok8/small-package?color=blueviolet">
</div>


#### small-package

*  常用OpenWrt软件包源码合集，同步上游更新！

*  关于有好的插件请在issues提交

*  感谢以上github仓库所有者！

##### 插件下载:

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/kenzok8/compile-package?style=for-the-badge&label=插件更新下载)](https://github.com/kenzok8/compile-package/releases/latest)

#### 使用方式：

```bash
 sed -i '$a src-git smpackage https://github.com/kenzok8/small-package' feeds.conf.default
```
对于强迫症的同学（有报错信息、或Lean源码编译出错的情况），请尝试删除冲突的插件

```bash
rm -rf feeds/smpackage/{base-files,dnsmasq,firewall*,fullconenat,libnftnl,nftables,ppp,opkg,ucl,upx,vsftpd*,miniupnpd-iptables,wireless-regdb}
```

#### 常用插件说明：

本仓库包含众多常用OpenWrt插件，包括但不限于：

* **科学上网类**：luci-app-passwall, luci-app-passwall2, luci-app-ssr-plus, luci-app-openclash, luci-app-bypass等
* **网络工具类**：luci-app-mosdns, luci-app-smartdns, luci-app-adguardhome等
* **系统增强类**：luci-app-advanced, luci-app-diskman, luci-app-dockerman等
* **存储与下载**：luci-app-alist, luci-app-aria2, luci-app-qbittorrent等
* **主题类**：luci-theme-argon, luci-theme-design, luci-theme-edge等

> **注意**：Passwall 和 Passwall2 都在本仓库中持续维护更新，请放心使用！











