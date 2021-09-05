![kenzo github stats](https://github-readme-stats.vercel.app/api?username=kenzok8&show_icons=true&theme=merko)
<div align="center">
<h1 align="center">small_action</h1>
<img src="https://img.shields.io/github/issues/kenzok8/small-package?color=green">
<img src="https://img.shields.io/github/stars/kenzok8/small-package?color=yellow">
<img src="https://img.shields.io/github/forks/kenzok8/small-package?color=orange">
<img src="https://img.shields.io/github/license/kenzok8/small-package?color=ff69b4">
<img src="https://img.shields.io/github/languages/code-size/kenzok8/small-package?color=blueviolet">
</div>


#### small-package

*  常用OpenWrt软件包源码合集，同步上游更新！

*  18.06版luci请使用18.06分支

*  19.07版luci请使用19.07分支

*  关于指定19.07分支下载示例:

```bash
 git clone -b 19.07 https://github.com/kenzok78/small-package
```

*  lean源码用18.06分支

*  官方源码用19.07分支




##### 关于Secrets、TOKEN的小知识

* 云编译或者fork同步仓库等需要 [在此](https://github.com/settings/tokens) 创建个token,然后在此仓库Settings->Secrets中添加个名字为ACCESS_TOKEN的Secret,填入token值

* 对应.github/workflows目录下的yml工作流文件里的ACCESS_TOKEN名称（依据自己yml文件修改）

* 在仓库Settings->Secrets中添加 SCKEY 可通过[Server酱](http://sc.ftqq.com) 推送编译结果到微信

* 在仓库Settings->Secrets中添加 TELEGRAM_CHAT_ID, TELEGRAM_TOKEN 可推送编译结果到Telegram Bot




#### 使用方式（三选一）：

1. 先cd进package目录，然后执行

```bash
 git clone https://github.com/kenzok78/small-package
```
2. 或者添加下面代码到feeds.conf.default文件

```bash
 src-git small8 https://github.com/kenzok78/small-package
```
3. lede/下运行 或者openwrt/下运行

```bash
git clone https://github.com/kenzok78/small-package package/small-package
```











