# Aliyun Acorn Nix Cache Mirror - 日志

## 会话进展 (2026-06-29)

### 已完成

- 按用户当前请求恢复并刷新 task contract：范围从单一 TUNA mirror 扩展为 TUNA、USTC、SJTU 三组 domestic substituters，并新增 `aliyun-acorn` firewall TCP 2222。
- 将验收标准更新为必须保留/添加官方 `cache.nixos.org` fallback 与 trusted public key，并验证 `./hosts/aliyun-acorn/image#aliyun-image` 的 `nix eval` 或 dry-run build。
- 确认主工作区开始时 `git status --short` 无输出，暂无 unrelated dirty changes 需要隔离。
- 从 `origin/master` 创建隔离 worktree `.worktrees/aliyun-acorn-nix-cache-mirror`，分支 `legion/aliyun-acorn-nix-cache-mirror`。
- 在 `hosts/aliyun-acorn/default.nix` 扩展 host-level `nix.settings.substituters`：TUNA、USTC、SJTU 依次优先于既有 Cachix 与官方 cache。
- 在 `hosts/aliyun-acorn/default.nix` 的 `networking.firewall.allowedTCPPorts` 添加 `2222`。
- 验证通过：最终 substituters、trusted public keys、allowed TCP ports 与 `./hosts/aliyun-acorn/image#aliyun-image.drvPath` 均符合验收。
- Change review 通过，结论 PASS；安全视角覆盖 Nix cache trust chain 与 TCP 2222 暴露面。
- 更新 `docs/report-walkthrough.md` 与 `docs/pr-body.md`，并删除过期的 TUNA-only `docs/report-walkthrough.html` artifact。
- 完成 wiki writeback：更新 `decisions.md`、`patterns.md`、任务摘要和 wiki log，记录三镜像顺序、official key/fallback 验证、TCP 2222 scope 与 image target 验证模式。

### 进行中

- 进入 Git lifecycle：提交、rebase、push/PR 或记录 blocker。

### 阻塞/待定

- 无当前实现阻塞。

---

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
