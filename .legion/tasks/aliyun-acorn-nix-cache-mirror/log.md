# Aliyun Acorn Nix Cache Mirror - 日志

## 会话进展 (2026-06-20)

### 已完成

- 建立 task id `aliyun-acorn-nix-cache-mirror`。
- 从 `origin/master` 创建 worktree `.worktrees/aliyun-acorn-nix-cache-mirror`，分支 `legion/aliyun-acorn-nix-cache-mirror`。
- 将任务范围限定为 `aliyun-acorn` host-level Nix binary cache mirror，不改全局 flake inputs。
- 在 `hosts/aliyun-acorn/default.nix` 添加 TUNA substituter，使用 `lib.mkBefore` 保留现有 fallback。
- 验证最终 substituter 顺序和 `aliyun-acorn` toplevel drv 求值。
- 完成 change review，结论 PASS。
- 生成 `docs/report-walkthrough.md`、`docs/report-walkthrough.html` 和 `docs/pr-body.md`。
- 运行 `pr-html-render` 判断，记录 rendered preview 为 artifact-only/blocker；本任务不新增 Pages workflow。
- 完成 wiki writeback：新增 task summary，并更新 Aliyun/Nix cache 相关 decisions/patterns。

### 进行中

- 提交分支并按 PR lifecycle 推进。

### 阻塞/待定

- 无实现阻塞。
- 主工作区存在用户/其他任务未提交改动，最终 cleanup/main refresh 需要避免覆盖这些改动。

---

## 关键文件

**`hosts/aliyun-acorn/default.nix`** [modified]
- 作用: `aliyun-acorn` NixOS host 配置；新增 host-level cache mirror。

**`.legion/tasks/aliyun-acorn-nix-cache-mirror/`** [new]
- 作用: 本任务 contract、验证、review 和交付证据。

---

## 关键决策

| 决策 | 原因 | 替代方案 | 日期 |
|------|------|----------|------|
| 只在 `aliyun-acorn` prepend TUNA substituter | 阿里云机器需要国内 cache，但不应影响其他 hosts | 改全局 `default.nix` 或 flake inputs | 2026-06-20 |
| 保留 Cachix 和官方 cache fallback | 国内动态 cache 可能缺 nar；fallback 降低失败概率 | `lib.mkForce` 只使用国内 mirror | 2026-06-20 |

---

## 快速交接

**下次继续从这里开始：**
1. 运行 `nix eval` 验证最终 substituter 顺序。
2. 提交分支并按 PR lifecycle 推进，若权限/网络阻塞则记录 handoff。

**注意事项：**
- 不要把主工作区现有 dirty changes 混入本任务。
- 不要改 `flake.nix` / `flake.lock` 的 input 来源。

---

*Updated: 2026-06-20 00:00*
