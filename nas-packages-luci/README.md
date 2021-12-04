# nas-packages-luci
luci for [nas-packages](https://github.com/linkease/nas-packages)

## 使用方法

### 增加feed源

```shell
echo >> feeds.conf.default
echo 'src-git nas https://github.com/linkease/nas-packages.git;master' >> feeds.conf.default
echo 'src-git nas_luci https://github.com/linkease/nas-packages-luci.git;main' >> feeds.conf.default
./scripts/feeds update nas nas_luci
./scripts/feeds install -a -p nas
./scripts/feeds install -a -p nas_luci
```

### 集成软件包

```shell
make menuconfig
```

选择软件包
```plain
LuCI --->
3. Applications --->
<*> luci-app-ddnsto.................................. LuCI support for ddnsto
<*> luci-app-linkease.................................. LuCI support for linkease
```

### 构建固件
```shell
make
```