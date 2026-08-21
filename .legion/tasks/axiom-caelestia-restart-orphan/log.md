# Axiom Caelestia 重启孤儿 shell 回收 - 日志

## 会话进展 (2026-08-21)

### ✅ 已完成

- 诊断根因：NixOS 切换后旧代 caelestia-shell 的 config path 与当前代不同，`stop()`/`instance_pid()` 的 config 键控/精确路径匹配漏掉旧代实例。
- 提取共享 `list_shell_pids()`（后缀正则 `/^  Config path: .*\/share\/caelestia-shell\/shell\.qml$/`），`instance_pid()` 用 while-read 进程替换取首个匹配（避免 `head` SIGPIPE 在 `pipefail` 下误伤），`stop()` 逐个 `kill --pid`。
- 新增 `caelestiaSessionControlTest` runCommand 并接入 `system.extraDependencies`；测试用 `sed` 从真实 shipped 脚本提取函数后跑跨代正例与负例 fixture。
- 本地独立构建 `caelestia-session` 与 `caelestia-session-control-test` 两个 drv 全部通过。

### 🟡 进行中

- 等待 PR 合并后 `nixos-rebuild switch --flake .#axiom` 部署，并用 `caelestia-shell list --all` 确认单实例。

### ⚠️ 阻塞

- (none)
