# Axiom 锁屏后 DPMS 延迟 - 日志

## 会话进展 (2026-08-20)

### ✅ 已完成

- 完成标准 RFC 和对抗审查；设计门通过。
- 实现 Axiom 锁定状态关联的 60 秒 DPMS 定时器、epoch 取消防护和锁屏输入唤醒逻辑。
- 完成补丁/配置/package-build 验证、变更审查、交付摘要和 wiki 写回。

### 🟡 进行中

（无）

### ⚠️ 阻塞/待定

- 部署后仍需执行图形会话 smoke：手动/空闲/logind 锁屏、提前解锁、快速解锁重锁，以及保持锁定时的物理输入唤醒。

---

## 关键文件

- **`.legion/tasks/axiom-lock-dpms-delay/docs/test-report.md`** [completed]
  - 作用: 记录补丁、配置和普通 Git-backed Caelestia 包构建验证。
  - 备注: 图形会话 DPMS smoke 留作部署后验证。

- **`modules/desktop/caelestia-lock-dpms-timeout.patch`** [completed]
  - 作用: 为固定 Caelestia 版本添加默认关闭的锁屏 DPMS 超时状态机。
  - 备注: 仅 Axiom 通过 `lockDpmsTimeout = 60` 启用。

---

## 关键决策

| 决策 | 原因 | 替代方案 | 日期 |
|------|------|----------|------|
| 使用默认关闭的上游补丁，而非手工锁屏包装器 | 所有受支持锁屏入口在 `WlSessionLock.locked` 状态收敛，并复用 Caelestia DPMS action seam。 | 只包装手动锁屏命令；把全局 DPMS 改为 960 秒。 | 2026-08-21 |

---

## 快速交接

**下次继续从这里开始：**

1. PR 合并并部署后，执行 `.legion/wiki/maintenance.md` 中记录的图形会话 smoke。

**注意事项：**

- 静态、配置和定向包构建验证均通过；尚未执行部署或图形会话验证。

---

*最后更新: 2026-08-21 07:09 by Legion CLI*
