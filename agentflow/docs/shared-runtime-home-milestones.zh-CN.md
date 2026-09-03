# AgentFlow 共享 Runtime HOME 实施里程碑

## 目标架构

AgentFlow 的应用数据和设备级开发运行时分离：

- AgentFlow 数据目录：`<quickstart.conf_dir>/AgentFlow`
- 共享 Runtime HOME：`<quickstart.conf_dir>/Runtime/home`

共享 Runtime HOME 由 `mise` 包提供公共 helper 初始化，AgentFlow 和后续运行时感知应用复用同一套 `HOME`、XDG、`MISE_*` 和 `PATH`。

## Milestone 1：公共 Runtime HOME 合约

目标：

- `mise` 包安装 `/etc/config/mise`。
- `mise` 包安装 `/lib/functions/istore_runtime.sh`。
- helper 自动从 `quickstart.main.conf_dir` 推导 `<conf_dir>/Runtime/home`。
- helper 支持 `ISTORE_RUNTIME_CONF_DIR` 兜底，便于应用从自身 Configs 目录派生 Runtime。
- helper 统一导出 `HOME`、`XDG_DATA_HOME`、`XDG_CACHE_HOME`、`XDG_CONFIG_HOME`、`XDG_STATE_HOME`、`MISE_DATA_DIR`、`MISE_CACHE_DIR`、`MISE_CONFIG_DIR`、`MISE_STATE_DIR` 和 `PATH`。

验收：

- 新安装 `mise` 后，存在 `/etc/config/mise` 和 `/lib/functions/istore_runtime.sh`。
- 已配置 quickstart 时，初始化路径为 `<quickstart.conf_dir>/Runtime/home`。
- 未配置 quickstart 但应用提供 `ISTORE_RUNTIME_CONF_DIR` 时，初始化路径为 `$ISTORE_RUNTIME_CONF_DIR/Runtime/home`。

## Milestone 2：AgentFlow 接入共享 Runtime HOME

目标：

- AgentFlow 不再使用 `$data_dir/global` 作为 `HOME` 或 mise shim 根。
- AgentFlow 启动时调用 `istore_runtime_export_env`。
- `AGENT_FLOW_DATA` 继续固定在 AgentFlow 数据目录下的 `data` 子目录。
- AgentFlow 服务进程及其子进程继承共享 Runtime HOME。

验收：

- `/etc/init.d/agentflow start` 后，AgentFlow 进程环境中 `HOME=<conf_dir>/Runtime/home`。
- `MISE_DATA_DIR=$HOME/.local/share/mise`。
- `PATH` 以 `$MISE_DATA_DIR/shims:$HOME/.local/bin` 开头。
- AgentFlow 数据库仍写入 `<conf_dir>/AgentFlow/data/db/db.sqlite`。

## Milestone 3：LuCI 可见性

目标：

- AgentFlow LuCI 页面继续配置 AgentFlow 数据目录。
- 页面展示推导出的共享 Runtime HOME。
- 如果 `mise.runtime_dir` 被显式设置，页面展示其对应的 `home`。

验收：

- quickstart `conf_dir=/mnt/vio3-1/Configs` 时，页面显示 `/mnt/vio3-1/Configs/Runtime/home`。
- AgentFlow 数据目录仍显示 `/mnt/vio3-1/Configs/AgentFlow`。

## Milestone 4：迁移与兼容

目标：

- 新安装默认使用共享 Runtime HOME。
- 老安装中已有 `$data_dir/global/.local/share/mise` 时，不自动移动大目录。
- 后续提供显式迁移命令或 LuCI 操作。

验收：

- 升级不会删除或搬移旧 runtime 数据。
- 用户确认迁移后，旧 mise data 可迁移到 `<conf_dir>/Runtime/home/.local/share/mise`。
- 迁移失败不会影响 AgentFlow 私有数据。

## Milestone 5：AgentFlow 后端项目环境集成

目标：

- OpenWrt 层面完成共享 HOME 后，再在 AgentFlow 后端引入项目环境 wrapper。
- coding agent 进程使用 `mise exec -- <agent> ...` 应用项目 `mise.toml`。
- 运行期设置 `MISE_EXEC_AUTO_INSTALL=0`，缺失工具只在准备阶段安装。

验收：

- 单 repo 项目中，agent 看到项目声明的 Node/Python/Go 版本。
- 没有隐式运行期下载。
- Codex/Claude/Kimi 等 agent 凭据继续来自共享 Runtime HOME。
- 取消任务时 wrapper 和 agent 子进程都能退出。
