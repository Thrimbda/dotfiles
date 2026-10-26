# Dotfiles Git State Reconciliation

## 元数据

- `name`: Dotfiles Git State Reconciliation
- `task-id`: `dotfiles-reconcile-git-state-20260907`
- `status`: active
- `risk`: high
- `profile`: Strict

## 目标

逐项审计 `/Users/c1/dotfiles` 主工作区和所有 linked worktree 的本地 Git 状态；把有长期价值且尚未被远端覆盖的内容整理、验证并通过 squash PR 合入，精确丢弃已被覆盖、过期重复或纯临时内容，最终使主工作区处于 `master`、状态干净并与最新 `origin/master` 完全一致。

## 问题陈述

主工作区同时存在落后远端的 `master`、staged wiki 修改、未跟踪 task/wiki、一个秘密样文件与多个历史 worktree。部分 worktree 的 PR 已合并，部分仍含未提交验证资料；squash merge 又会让简单 ancestry 检查产生误判，因此不能直接 `pull`、`reset --hard`、广域 `git clean` 或整体删除 `.worktrees/`。

## 验收标准

- [ ] 对主工作区、全部 linked worktree、相关分支/PR、未提交及未跟踪文件形成逐项处置结论与依据。
- [ ] 每个删除目标均已证明无独有提交价值、已被远端等价覆盖，或其有价值内容已先行转移。
- [ ] 候选提交不包含密码、私钥、token、cookie、pairing URL 或其它秘密/秘密派生值。
- [ ] 有价值内容从最新 `origin/master` 的隔离 worktree 提交、rebase、push，并以 squash PR 到达终态；不直接提交或 push `master`。
- [ ] 已合并且无独有内容、无运行中进程占用的历史 worktree 被清理；不删除归属或价值无法证明的工作。
- [ ] 最终重新 fetch 后当前分支为 `master`，`git rev-list --left-right --count HEAD...origin/master` 为 `0 0`，`git status --short` 为空，`git worktree list` 只保留主工作区。

## 假设 / 约束 / 风险

- **假设**：`origin/master` 是目标真源；用户已授权精确丢弃无提交价值的本地改动。
- **约束**：`acorn_password` 仅以路径、类型、权限、大小与引用关系作不透明处理；不得读取、打印、暂存或提交其内容。
- **约束**：不执行 Aliyun ECS、Constx、RustDesk 或 Doom 的部署/运行时任务；不修改仓库外配置。
- **约束**：禁止 `reset --hard`、广域 `git clean`、整体递归删除 `.worktrees/` 与宽范围 stash。
- **约束**：按来源拆分处置；有价值内容先转移到最新远端基线，再清理主工作区原件。
- **风险**：squash merge 的 ancestry 不等价可能造成覆盖误判。
- **风险**：Constx dirty worktree 可能混有过期状态与仍有历史价值的生产证据。
- **风险**：远端推进可能与 staged wiki 修改冲突。
- **风险**：误删秘密样文件或仍被进程使用的 checkout 可能造成不可逆运行损失。

## 要点

- 建立资产表，联合使用 reachability、tree/diff、patch/内容等价、PR 终态、当前 wiki 真相与进程占用判断。
- 价值标准优先保留可验证的完成证据、当前真相和可复用决定；空骨架、重复事实、过期状态和缓存通常不保留。
- 先交付保留项，再逐路径清理；所有删除均采用可恢复或 Git-aware 的精确操作。
- 最终以实时 fetch、`0 0`、clean status 和单一 worktree 给出证明。

## 范围

- 主工作区现有 staged/untracked 状态。
- `.worktrees/*` 中四个既有 worktree 及本任务 worktree的 dirty state、commit、branch、PR 和进程占用。
- `doom-org-norang-minimal`、`aliyun-nixos-ecs-deploy`、Doom wiki writeback与 Constx rollout evidence。
- `acorn_password` 的不透明秘密样 artifact 处置。
- `master` 相对最新 `origin/master` 的同步与最终证明。

### 非目标

- 不恢复或继续任何部署/运行时任务。
- 不查看、迁移、轮换或披露任何密码或密钥。
- 不清理无关全局 Git 分支、其它仓库或系统缓存。
- 不把无法证明归属、合并终态或内容价值的独有工作当作垃圾删除。

## 设计索引

> **Design Source of Truth**: `.legion/tasks/dotfiles-reconcile-git-state-20260907/docs/rfc.md`

设计将定义等价判定、秘密边界、处置顺序、恢复点、验证矩阵与 PR/cleanup 门禁。

## 关键主张

| Claim | 主张 | 类型 / 时机 | criticality / policy |
| --- | --- | --- | --- |
| C1 | 删除前，每个 worktree、分支和本地 diff 已被远端等价覆盖或已转移保留。 | objective / now | high / block-stage |
| C2 | 候选提交与 PR 不含秘密或秘密派生值。 | objective / now | high / block-merge |
| C3 | 逐项保留/丢弃判断符合 durable truth、独有性、可复用性、时效性与可逆性标准。 | judgmental / now | high / block-stage |
| C4 | 最终本地主工作区与最新远端完全一致。 | formal / now | high / block-stage |

## 阶段概览

1. `brainstorm`：收敛审计 contract。
2. `spec-rfc -> review-rfc`：确定等价判定、秘密边界、恢复与清理顺序。
3. `engineer`：转移保留项并精确处置无价值项。
4. `verify-change -> review-change`：验证内容、秘密、Git/PR 覆盖和删除安全。
5. `git-worktree-pr`：commit、rebase、push、PR、checks/review、squash merge。
6. 终态 cleanup 与主工作区刷新，证明 `0 0 + clean + single worktree`。
