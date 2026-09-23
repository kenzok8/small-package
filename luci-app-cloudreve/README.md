# luci-app-cloudreve

把 [Cloudreve](https://github.com/cloudreve/cloudreve) 做成 **iStoreOS / OpenWrt 的原生 LuCI 应用**：
一个不到 20KB 的 ipk，装完在路由器管理页面里点几下，就跑起来一个私有网盘。

> 一句话概括：**不打包二进制 + 外置硬盘存数据 + 自动识别架构在线拉取**。

---

## ✨ 特性

| 特性 | 说明 |
|---|---|
| 🪶 **极小体积** | ipk 只有约 **17KB**，里面**不含** Cloudreve 本体（那玩意儿几十 MB，塞进路由器闪存太奢侈） |
| 🧠 **架构自动识别** | 自动判断路由器是 `aarch64 / x86_64 / armv7 / mips…`，从 GitHub 拉对应版本的二进制 |
| 💾 **外置硬盘约定** | 遵循 iStoreOS 的 `Configs` 规范，程序与数据库落在 `<硬盘>/Configs/cloudreve/`，**不占路由器闪存** |
| 🇨🇳 **全中文界面** | 状态 / 初始化 / 下载 / 服务控制 / 日志，五个区块全部中文，带完整操作提示 |
| 🔁 **procd 托管** | 开机自启、崩溃自动拉起，符合 OpenWrt 原生习惯 |
| 🖱️ **一键运维** | 页面上直接「启动 / 停止 / 重启」，不用 SSH 敲命令 |

---

## 📦 安装

### 方式一：iStore 图形界面（推荐）
1. 到本仓库 [Releases](../../releases) 下载 `luci-app-cloudreve_x.x.x_all.ipk`
2. iStore → 手动安装 ipk → 选中文件
3. 刷新页面，菜单出现在 **服务 → Cloudreve**（或 NAS 分类下）

### 方式二：SSH 命令行
```sh
opkg update
opkg install luci-app-cloudreve_0.0.1_all.ipk
```

> ⚠️ **降级安装**必须加参数，否则 opkg 会拒绝：
> ```sh
> opkg install --force-downgrade luci-app-cloudreve_0.0.1_all.ipk
> ```

---

## 🚀 使用（三步走）

1. **选硬盘 → 「创建 Configs 目录」**
   页面会自动列出可写的外置挂载点，选一个（建议空间最大的）。
2. **点「下载最新二进制」**
   自动识别架构、从 GitHub 拉取、赋予执行权限。
3. **勾选「启用服务」→「保存并应用」**
   然后浏览器打开 `http://<路由器IP>:5212`，第一次进去注册的管理员就是超级管理员。

> 💡 如果点了保存没起来，直接用页面上的 **「服务控制」→ 启动**。
> 这是 LuCI 的一个通用坑：「保存并应用」走的是 `procd reload`，**不会拉起一个从来没运行过的服务**。

---

## ⚠️ 装机后必做一件事：改「站点 URL」

Cloudreve 出厂的站点 URL 默认是 **`http://localhost:5212`**。

不改的话：文件**能正常上传**，但**缩略图和预览全部加载不出来**，浏览器 F12 会看到一堆
`http://localhost:5212/... net::ERR_CONNECTION_REFUSED`。
（原因：服务端按这个地址拼直链，你在局域网访问时浏览器会去找"自己电脑"的 5212 端口。）

**改法**：Cloudreve 管理面板 → 参数设置 → 站点 URL → 填 `http://<路由器IP>:5212`

> 这个输入框**系统会自动补 `http://`**，所以你**只填 `192.168.100.1:5212` 就行**，
> 别自己再加协议头、别加结尾斜杠，否则会变成 `http://http://.../` 这种畸形值。

---

## 🗂 仓库结构（OpenWrt feed 源码包）

本仓库**本身就是一个标准 OpenWrt 包**，可直接放进
[openwrt-app-actions](https://github.com/linkease/openwrt-app-actions) 的
`applications/luci-app-cloudreve/` 由 CI 编译。

```
luci-app-cloudreve/
├── Makefile                    # 包定义（版本 / 依赖 / conffiles / 卸载脚本）
├── luasrc/                     # → 装到 /usr/lib/lua/luci/
│   ├── controller/cloudreve.lua
│   ├── model/cloudreve.lua     # 硬盘探测 + iStoreOS 目录约定
│   ├── model/cbi/cloudreve/    # 配置页（目录形态，避开同名冲突）
│   └── view/cloudreve/         # status / download / initdir / svcctl / log
├── po/zh-cn/cloudreve.po       # 中文翻译（135 条）
├── root/                       # → 装到设备根目录 /
│   ├── etc/config/cloudreve
│   ├── etc/init.d/cloudreve    # procd 托管
│   ├── etc/uci-defaults/cloudreve
│   ├── usr/libexec/cloudreve/detect_base.sh  # 硬盘探测
│   └── usr/share/rpcd/acl.d/luci-app-cloudreve.json
└── tools/                      # 本地校验脚本（Lua 配平 / 布局 / BOM）
```

> **目录映射铁律**：`luasrc/` → `/usr/lib/lua/luci/`，`root/` → `/`。
> 由 `feeds/luci/luci.mk` 自动完成，别手写路径。
> ⚠️ 千万别写成 `/usr/lib/luci/view/...` —— 少了 `lua` 这层会整页 500。

---

## 🔧 编译 / 使用

### 方式一：交给 openwrt-app-actions 的 CI（推荐）
1. fork [linkease/openwrt-app-actions](https://github.com/linkease/openwrt-app-actions)
2. 把本仓库放到 `applications/luci-app-cloudreve/`
3. Actions → **Build IPKs** → 输入 `luci-app-cloudreve`
4. CI 自动编译出 **arm64 / x64 / mipsel / arm 四架构** + **ipk / apk 双格式**

### 方式二：本地用 OpenWrt SDK 编译
```sh
echo "src-link apps $(pwd)/applications" >> feeds.conf
./scripts/feeds update -a && ./scripts/feeds install -d y luci-app-cloudreve
make package/luci-app-cloudreve/compile V=s
```

### 本地自检（提交前必跑）
```sh
python tools/check_lua.py luasrc     # Lua 块配平
python tools/check_bom.py  luasrc    # 中文文件禁 BOM
```

---

## ✅ 兼容性

- **已实测**：iStoreOS（aarch64 软路由）+ Cloudreve **V4.19.1**
- **理论上支持**：OpenWrt 21.02 / 22.03 / 23.05（需 LuCI + rpcd + procd）
- **Cloudreve 版本**：仅支持 **V4**（V3 的配置格式与数据库位置都不一样）

---

## 🐞 已知问题

| 问题 | 说明 |
|---|---|
| webp 缩略图不生成 | Cloudreve 内置缩略图生成器不支持 webp（Go 标准库不解码），文件会被标 `thumb:disabled`，只显示文件图标。需要外部生成器（ffmpeg / libvips）才能支持 |
| 头像接口 404 | 未上传头像时 `/api/v4/user/avatar/<uid>` 返回 404，纯噪音，不影响使用 |
| 站点 URL 要手填 | 出厂默认 localhost，见上文「装机后必做」（计划后续版本自动写入 LAN IP） |

---

## 🧠 开发踩坑笔记（节选）

做这个包踩过的坑，都写在这几个地方，做第二个 LuCI 应用时可以直接当检查表用：

- Cloudreve V4 必须 `cloudreve server -c conf.ini`，裸跑只打印 usage 就退出
- V4 的 `conf.ini` **只有 `[System]` 段**，没有 `[Database]`，数据库固定在 `可执行文件所在目录/data/cloudreve.db`
- LuCI「保存并应用」≠ 启动服务（reload 拉不起未运行实例）
- LuCI 模板解析器是 **C 扩展**，多块 `<% %>` 与 CSS 里的 `%` 混用会炸整页 500 → 一律单块 `table.concat` 输出
- 没有 lmo 翻译文件时，中文只能**硬编码**，`translate()` / `<%: %>` 必然失效
- `model/cbi/` 下禁止 `x.lua` 与 `x/` 同名共存，否则整个 LuCI 全站 500
- 别在 `postinst` 里 `rpcd restart`，会把所有登录会话踢掉

---

## 📄 License

[MIT](LICENSE)

---

## 🙏 致谢

- [Cloudreve](https://github.com/cloudreve/cloudreve) —— 优秀的国产 Go 网盘程序
- [luci-app-filebrowser](https://github.com/…) —— ipk 打包格式的字节级参考对象
- iStoreOS 社区 —— `Configs` 目录约定
