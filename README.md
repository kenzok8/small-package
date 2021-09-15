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

*  18.06版luci请使用18.06分支

*  19.07版luci请使用19.07分支

*  关于指定19.07分支下载示例:

```bash
 git clone -b 19.07 https://github.com/kenzok8/small-package
```

*  lean源码用18.06分支

*  官方源码用19.07分支

##### 插件下载:


[![GitHub release (latest by date)](https://img.shields.io/github/v/release/kenzok78/compile-packages?style=for-the-badge&label=Download)](https://github.com/kenzok78/compile-packages/releases/latest)


##### 关于Secrets、TOKEN的小知识


1. 首先需要获取 **Github Token**: [点击这里](https://github.com/settings/tokens/new) 获取,

 `Note`项填写一个名称,`Select scopes`不理解就**全部打勾**,操作完成后点击下方`Generate token`

2. 复制页面中生成的 **Token**,并保存到本地,**Token 只会显示一次!**

3. **Fork** 我的`small-package`仓库,然后进入你的`small-package`仓库进行之后的设置

4. 点击上方菜单中的`Settings`,依次点击`Secrets`-`New repository secret`

其中`Name`项填写`ACCESS_TOKEN`,然后将你的 **Token** 粘贴到`Value`项,完成后点击`Add secert`

* 对应`.github/workflows`目录下的`yml`工作流文件里的`ACCESS_TOKEN`名称（依据自己yml文件修改）

* 在仓库`Settings->Secrets`中添加 `SCKEY `可通过[Server酱](http://sc.ftqq.com) 推送编译结果到微信

* 在仓库`Settings->Secrets`中添加 `TELEGRAM_CHAT_ID, TELEGRAM_TOKEN `可推送编译结果到`Telegram Bot`




#### 使用方式（三选一）：

1. 先cd进package目录，然后执行

```bash
 git clone https://github.com/kenzok8/small-package
```
2. 或者添加下面代码到feeds.conf.default文件

```bash
 src-git small8 https://github.com/kenzok8/small-package
```
3. lede/下运行 或者openwrt/下运行

```bash
git clone https://github.com/kenzok8/small-package package/small-package
```











