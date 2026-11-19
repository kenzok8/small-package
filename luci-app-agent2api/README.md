# luci-app-agent2api

Agent2API 的 iStoreOS / OpenWrt LuCI 应用（Docker 形态）。

- 底层镜像：`aimodcc/agent2api:latest`（amd64 / arm64）
- 面板/网关端口：`3065`（可在 LuCI 页面修改）
- 数据卷：LuCI 中选择的 `config_path` 映射到容器 `/data`（SQLite 库、配置、日志、插件）
- 默认数据目录：优先使用 iStoreOS quickstart 的 `Configs` 目录下的 `Agent2API`；未配置且存在磁盘候选时选择首个磁盘，无磁盘候选时回退到 `/root/Configs/Agent2API`。
- 镜像拉取加速：遵循 Docker 的全局镜像源设置；需要加速时在全局配置中启用 KSpeeder/iStoreEnhance。插件不提供独立加速开关，旧配置中的 `install_accelerated` 不再使用。

## 安装

1. 设备需已安装 Docker（iStore 商店的 Docker 面板）。
2. 在 LuCI「服务 → Agent2API」选择数据目录（建议 NVMe/外置盘），保存并应用。
3. 首次打开面板后注册管理员，并在「网关 Key」页创建 API Key；未创建 Key 前 `/v1/*` 拒绝服务（fail-closed）。

## 回归检查

在仓库根目录运行 `python3 applications/luci-app-agent2api/tests/test_agent2api.py`。目录逻辑测试需要 Lua 5.1 或 LuaJIT 共享库；未安装时会明确显示跳过。测试使用临时目录和模拟 UCI/Docker 命令，不访问真实 Docker 服务。
