# Auth Mini Gateway Pin 2026-07-30 - 日志

## 会话进展 (2026-07-31)

### ✅ 已完成

- 验证 Acorn 运行时：`/run/current-system` 中两个 gateway 实例均 active，ExecStart 指向 `/nix/store/q62fpw730jv2c6hwh1swnysh5ih434bl-auth-mini-gateway-0.1.0-unstable-2026-07-30`。
- 在 Axiom 本机以上游 master `e1ea3e77fc39612b7418a3a44db5e2cc2b8618d4` 构建 package，产出 store path 与 Acorn 运行中的完全一致（byte-identical）。
- 发现 `origin/master` 已包含 pin 更新（commit `8872e1f8` fix(auth-mini): migrate gateways to user id audience (#157)），版本 `0.1.0-unstable-2026-07-30`、src hash `sha256-gkaFhFbPk/oyyYrnOJzeRs0oexMQTMH7y5Ci3exqPxk=`。
- 从 worktree（origin/master）构建 package，产出同样为 `q62fpw730jv2c6hwh1swnysh5ih434bl`，三方（声明式 pin / Axiom 构建 / Acorn 运行时）一致。
- 主工作区已确认在 `origin/master`（f11522d4）且工作树干净；无需 PR，worktree 与临时分支已清理。

### 🟡 进行中

(暂无)

### ⚠️ 阻塞/待定

(暂无)

---

## 关键文件

- `packages/auth-mini-gateway/default.nix`
- `hosts/acorn/modules/auth-mini.nix`

---

## 关键决策

| 决策 | 原因 | 替代方案 | 日期 |
|------|------|----------|------|
| 不开新 PR，直接关闭任务 | origin/master 已通过 #157 包含目标 pin，再开 PR 会产生空 diff | 强行 bump 产生 no-op PR | 2026-07-31 |
| 不 redeploy Acorn | 运行时 store path 与最新 pin 构建产物一致，rebuild 是 no-op | 再次 nixos-rebuild switch | 2026-07-31 |

---

## 快速交接

**下次继续从这里开始：**

任务已完成，无需继续。

**注意事项：**

- Acorn 的构建/部署仍须从 Axiom 发起，禁止在 Acorn 本机 build。

---

*最后更新: 2026-07-31 by Legion*
