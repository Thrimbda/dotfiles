# 任务清单

## 快速恢复

**当前阶段**：三台 switch 和验收完成，推进 PR 交付

## 阶段 1：实施

- [x] 批准方案、核实主机和隔离 worktree。
- [x] 声明 Samba、加密凭据、定向防火墙、FRP 和原生挂载。
- [x] 构建三台配置，保留已有本地配置改动。

## 阶段 2：部署验收

- [x] Axiom 与 Ant switch，Charles 最终客户端 user agent 部署。
- [x] Charles 解锁后完成最终整机 switch。
- [x] 比较三条路径，验证 P2P 原生 SMB、加密、完整性、保存、双向可见、冷启动与备用。

## 阶段 3：交付

- [x] 文档与证据，已更新最终 switch 状态。
- [ ] 提交、PR checks、squash merge、清理及安全刷新。
