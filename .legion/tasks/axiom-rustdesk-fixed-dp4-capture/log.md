# Axiom RustDesk fixed DP-4 capture - 日志

## 会话进展 (2026-07-30)

### ✅ 已完成

- 完成运行时诊断、RFC 与 RFC 对抗审查。
- 添加 rustdeskStateAccess ExecStartPre，隔离 c1 可写的 RustDesk2.toml。
- 通过完整 toplevel 构建、变更审查、walkthrough 和 wiki 写回。

### 🟡 进行中

- 创建、合并 PR 后从 refreshed origin/master 部署并执行远程验收。

### ⚠️ 阻塞/待定

- 运行时验收需要合并后的特权系统切换和远程 RustDesk 客户端。
---

## 关键文件

- **`hosts/axiom/default.nix`** [completed]
  - 作用: 在 RustDesk 服务启动前为 Config2 准备受限 c1 状态访问。
  - 备注: Root 服务环境和密码配置保持不变。
- **`.legion/tasks/axiom-rustdesk-fixed-dp4-capture/docs/rfc.md`** [completed]
  - 作用: 记录 DP-4 持久 portal 选择设计与回滚边界。
  - 备注: RFC review passed.
---

## 关键决策

| 决策 | 原因 | 替代方案 | 日期 |
|------|------|----------|------|
| 保留 root password state，仅让 c1 管理 RustDesk2.toml | RustDesk 将 Wayland restore token 保存于 Config2；c1 无法写 root config 会导致每次连接重新选屏。 | 虚拟输出与完整迁移到 c1 home 均被拒绝。 | 2026-07-30 |
---

## 快速交接

**下次继续从这里开始：**

1. 完成 PR 合并后部署 Axiom。
2. 进行两次远程 DP-4 无选择器连接测试。

**注意事项：**

- 不在 feature worktree 直接生产 switch。
---

*最后更新: 2026-07-30 08:21 by Legion CLI*
