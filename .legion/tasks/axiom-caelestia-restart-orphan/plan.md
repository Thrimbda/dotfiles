# Axiom Caelestia 重启孤儿 shell 回收

## 目标

让 Axiom 上 `caelestia-session restart` 能够可靠回收所有跨代（cross-generation）残留的 caelestia-shell 实例，使重启后只运行一个 shell 进程。

## 问题陈述

NixOS 重启/切换会替换 `caelestia-shell` 包路径（config path 变为新 store 路径）。原 `stop()` 只依赖 config 键控的 `caelestia-shell kill --any-display`，`instance_pid()` 用 awk 精确匹配完整 config 路径，两者都绑定当前代路径；旧代 shell 因 config path 不匹配而成为孤儿，导致重启后出现双 shell。

## 验收标准

- [x] `stop()` 按后缀正则 `/^  Config path: .*\/share\/caelestia-shell\/shell\.qml$/` 匹配任意 store 代路径，逐个 `kill --pid`。
- [x] `instance_pid()` 与 `stop()` 共享同一 `list_shell_pids()` 匹配逻辑，避免两处漂移。
- [x] 新增 `caelestiaSessionControlTest`（runCommand），随每次 axiom 部署构建：`bash -n` 生成脚本 + 对真实 shipped 函数跑跨代正例与负例 fixture。
- [x] 不改变 `start`/`run` 的现有语义（session_env、runner 循环、pid 文件、stop_file 均不变）。

## 假设 / 约束 / 风险

- **假设**: `caelestia-shell list --all` 输出格式 `Instance <id>:` / `  Process ID: <pid>` / `  Config path: <path>` 稳定。
- **约束**: 不修改 caelestia-shell 上游包本身。
- **约束**: 测试必须能在本地构建机独立构建，不依赖完整系统构建。
- **风险**: awk 提取依赖脚本内函数缩进/命名稳定 —— 已由测试中 `sed` 提取 + `grep` 存在性断言兜底。
- **风险**: `while read` 管道中 `kill` 失败不应中断其余回收 —— 用 `|| true` 兜底。

## 要点

- 后缀正则匹配，跨代通用
- `list_shell_pids` 单一事实来源
- runCommand 测试随部署执行

## 范围

- modules/desktop/caelestia.nix（控制脚本 + 测试 + extraDependencies 接线）
- .legion/tasks/axiom-caelestia-restart-orphan/ 下的任务文档
