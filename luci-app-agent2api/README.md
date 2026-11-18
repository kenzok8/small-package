# luci-app-agent2api

Agent2API 的 iStoreOS / OpenWrt LuCI 应用（Docker 形态）。

- 底层镜像：`aimodcc/agent2api:latest`（amd64 / arm64）
- 面板/网关端口：`3065`（可在 LuCI 页面修改）
- 数据卷：LuCI 中选择的 `config_path` 映射到容器 `/data`（SQLite 库、配置、日志、插件）

## 安装

1. 设备需已安装 Docker（iStore 商店的 Docker 面板）。
2. 在 LuCI「服务 → Agent2API」选择数据目录（建议 NVMe/外置盘），保存并应用。
3. 首次打开面板后注册管理员，并在「网关 Key」页创建 API Key；未创建 Key 前 `/v1/*` 拒绝服务（fail-closed）。
