# Axiom Caelestia 重启孤儿 shell 回收 - 任务清单

## 快速恢复

**当前阶段**: 阶段 3 验证与交付
**当前检查项**: PR 合并后部署 axiom 并验证单 shell 实例
**进度**: 3/3 任务完成
---

## 阶段 1: 诊断 ✅ COMPLETE

- [x] 定位孤儿 shell 根因：stop/instance_pid 均绑定当前代 config path | 验收: 复现双 shell 并确认旧代 PID 不被回收
---

## 阶段 2: 实现 ✅ COMPLETE

- [x] 提取共享 `list_shell_pids()`（后缀正则），重写 `instance_pid()` 与 `stop()`；新增 `caelestiaSessionControlTest` 并接入 `system.extraDependencies` | 验收: 跨代路径均被匹配并逐个回收，两处逻辑单一来源
---

## 阶段 3: 验证与交付 ✅ COMPLETE

- [x] 本地构建 `caelestia-session` 与 `caelestia-session-control-test` 两个 drv 全部通过（bash -n、正例、负例）；提交并走 worktree+PR | 验收: 测试 drv 在构建机独立构建成功，PR 合并后部署 axiom
---

## 发现的新任务
