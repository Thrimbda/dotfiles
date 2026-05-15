# OpenCode global auto-accept permissions - 日志

## 会话进展 (2026-05-15)

### ✅ 已完成

- Created Legion task contract and design-lite record.
- Updated ~/.config/opencode/opencode.json with permission=allow while preserving existing plugin and MCP keys.
- Verified JSON parse and permission value.
- Completed review, walkthrough, and wiki writeback.

### 🟡 进行中

- (暂无)

### ⚠️ 阻塞/待定

(暂无)

---

## 关键文件

- `~/.config/opencode/opencode.json` - User-level OpenCode runtime configuration; added `permission=allow` and preserved existing schema, plugin, and MCP config.

---

## 关键决策

| 决策 | 原因 | 替代方案 | 日期 |
|------|------|----------|------|
| Use global permission=allow for OpenCode auto-accept. | The user requested global default auto-accept behavior; OpenCode documents permission=allow as the durable config mechanism. | Per-session UI toggle; narrower edit-only allow with bash ask. | 2026-05-15 |

---

## 快速交接

**下次继续从这里开始：**

1. Restart or open a new OpenCode session if the running process does not reload config automatically.

**注意事项：**

- Project or agent permission settings can still override the global default.
- To revert, remove permission=allow or replace it with narrower rules such as edit=allow and bash=ask.

---

*最后更新: 2026-05-15 12:49 by Legion CLI*
