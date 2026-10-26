# RFC: Selective Git-State Reconciliation

> **Profile**: RFC Heavy / Strict
> **Status**: Draft
> **Created**: 2026-09-07
> **Last Updated**: 2026-09-07

## Executive Summary

本任务选择“选择性保留 + 先交付后精确清理”。Doom 完成证据，以及 Constx dirty evidence 中尚未被覆盖的 archive activation/rollback 事故模式，是本地仍有 durable value 的内容；它们将在最新 `origin/master` worktree上重放/提炼并随本审计证据提交。Aliyun 重复草案、Constx 过期 `FAIL / decide` 状态、Nix cache 与明文密码文件不进入 Git。任何原件和旧 worktree 的清理都推迟到保留 PR 已 squash merge、`origin/master` 已包含恢复点之后。最终刷新主工作区，再移除终态 worktree并证明 `0 0 + clean + single worktree`。

## 1. Context / Evidence

详细资产表见 `docs/research.md`。关键事实是：主工作区无本地领先提交但落后 11；Doom 外部实现已合并且 dotfiles 无证据；Aliyun 目标已由 PR #88 完成并被 host rename 更新；Constx 旧 dirty evidence 的 `FAIL / decide` 已被后续任务的用户 deferred 决定和完成交付替代；四个历史 worktree 无进程占用。

## 2. Goals / Non-goals

目标：保留唯一有价值内容、清理确认冗余/敏感/重建型状态、完成 squash PR 生命周期，并证明主工作区与远端一致。

非目标：继续任何历史任务、执行生产验证、读取或轮换秘密、删除无关远端分支或清理其它仓库。

## 3. Options

### Option A: 全部保留并分别提交

优点是最大化历史留存。缺点是会把过期 Aliyun host contract和 Constx `FAIL / decide` 重新引入当前真相，还会永久保存一次性秘密文件风险；不满足 wiki 与安全边界。

### Option B: 全部丢弃并直接 fast-forward

优点是最快。缺点是会丢失已被外部 PR 证明、但 dotfiles 尚无副本的 Doom 完成/验证/维护证据；不满足用户“有提交价值则整理提交”的要求。

### Option C: 选择性保留，先转移/交付再清理

优点是同时保住唯一 durable evidence、避免过期状态污染，并为每个破坏性动作提供可重算证据和恢复点。代价是需要一次文档 PR 与逐项 worktree cleanup。

## 4. Decision

选择 Option C。

### 4.1 保留单元

- 从主工作区把 `.legion/tasks/doom-org-norang-minimal/**`、`.legion/wiki/tasks/doom-org-norang-minimal.md` 及三项 wiki additions精确转移到当前隔离 worktree。
- Wiki additions 以追加/插入方式应用到最新文件，不用旧 staged blob 覆盖远端版本。
- 从 Constx dirty evidence 只提炼一条跨任务模式到最新 `.legion/wiki/patterns.md`：archive-based Nix deployment 在切换前必须枚举并复制 Git archive 不包含的 ignored encrypted source roots 与外部引用 source roots；缺失时立即回滚当前 generation，不读取 plaintext，补齐后先验证路径再重试。不得复制旧 `FAIL / decide`、时点运行态、record ID、IP 或完整 rollout report。
- 与本审计的 plan/research/RFC/verification/review 一起形成一个连贯的“恢复丢失完成证据并清理 Git 状态”文档 PR。

### 4.2 丢弃单元

- `.legion/tasks/aliyun-nixos-ecs-deploy/`：过期重复 contract；移到 Trash。
- `acorn_password`：不透明明文秘密样文件；在无 open handle 后移到 Trash，不读取内容。
- Constx public-deployment worktree dirty增量：后续 authoritative task 已改变状态和 completion disposition；原样提交会倒退真相。仅在 4.1 的事故模式已进入 squash-merged `origin/master` 后，使用 Git-aware worktree removal 丢弃整份旧增量。
- RustDesk `.cache/nix/**`：可重建缓存；随 worktree removal 丢弃。
- staged旧 wiki blobs与未跟踪 Doom 原件：只在隔离 worktree副本逐文件 hash/内容验证且最终 PR 合并后恢复/移除。

### 4.3 历史 worktree / branch cleanup

- #210 worktree HEAD 已在 `origin/master`；dirty增量按 4.2 处置。
- #211 与 #216 的 PR combined patch-id 分别等于 squash merge patch-id。
- RustDesk worktree HEAD 为 #139 remote PR head ancestor，#139 squash merge在 `origin/master`，combined patch-id 等价。
- 四者均无 `lsof +D` 占用。设计审查通过后移除 worktree；对应三个本地 Constx branch仅在 worktree移除后精确删除。远端 branch 不在本任务范围。

## 5. Claim Verification Design

| Claim | domain / capability / method | 原始证据 | 正向 / 失败判定 | owner |
| --- | --- | --- | --- | --- |
| C1 | `git-state` / routine / PR API + reachability + combined patch-id + worktree diff + `lsof` | `docs/research.md`，最终 `docs/test-report.md` | 所有删除目标均有覆盖或 disposition 且无占用 => PASS；任一独有/占用不明 => INCONCLUSIVE, block-stage | verifier |
| C2 | `secret-hygiene` / routine security lens / 仅扫描候选 diff与路径 metadata | 最终候选 diff、`git grep`/pattern scan摘要 | 无 secret marker且 `acorn_password` 从未进入 index => PASS；命中或需读取秘密才能判断 => FAIL/INCONCLUSIVE, block-merge | verifier |
| C3 | `repository-knowledge` / judgmental / 依据独有性、当前真相、可复用性、时效性、可逆性逐项 recommendation | 资产表、当前 wiki、PR终态 | 论证完整且事实/偏好分离 => RECOMMENDATION；真实分叉未解决 => stage FAIL + decide | RFC reviewer + user as decision owner |
| C4 | `git-state` / formal routine / final fetch + branch/upstream + rev-list + status + worktree list | 最终 `docs/test-report.md` 及结束时实时输出 | `master`, `0 0`, clean, single worktree => PASS；任一不满足 => FAIL, block-stage | verifier |

不需要外部 domain verifier 或 authority。GitHub PR API、Git对象图、patch-id、filesystem metadata和进程打开文件列表是本范围的直接数据源。C3 是 judgmental，用户的原请求允许对可逆默认项执行；独立 reviewer 负责提出最强反方理由。

## 6. Milestones / Ordering

1. **Design gate**：完成本 RFC 与独立 `review-rfc`；FAIL 则只修设计，不删除。
2. **Preserve**：把 Doom内容复制/重放到隔离 worktree，并把 Constx 独有事故提炼为 wiki pattern；验证文件集合、内容 hash、外部 PR终态、语义覆盖与最新 wiki合并结果。所有主工作区原件、秘密样文件和旧 worktree此时保持不动。
3. **Verification/review**：独立检查候选 diff、secret hygiene、语义提炼、远端覆盖和计划删除目标；review PASS 前不提交。
4. **Delivery recovery point**：commit、fetch/rebase、push、PR、checks/review与 squash merge；重新 fetch 并证明 `origin/master` 已包含 Doom证据和 Constx pattern。未合并则不清理任何原件/旧 worktree。
5. **Precise disposal**：即时重跑 PR/OID、dirty inventory、`lsof` 与秘密负向 Git检查；Trash过期 Aliyun草案与 `acorn_password`，Git-aware移除四个旧 worktree/对应本地任务 branch，恢复主工作区 staged旧 wiki并移除已转移 Doom原件。
6. **Final refresh**：清理本任务 worktree/branch，刷新主 `master`，证明 `0 0 + clean + single worktree`。

## 7. Rollback / Recovery

- Preserve、verification、review 与 PR merge 完成前，不清理任何主工作区原件、秘密样文件或旧 worktree；隔离副本验证失败则只修/删除副本，主工作区保持原状。
- Aliyun草案和 `acorn_password` 在 merge 后使用系统 Trash，属于可恢复删除；不使用递归 broad delete。
- 旧 worktree tracked内容由远端 PR/head/merge提供恢复；dirty Constx的独有事故语义由已合并 wiki pattern提供恢复；RustDesk cache可重建。任一实时复核失败就保留对应 worktree并停止。
- 主工作区 wiki只在 merge 后用精确 `git restore` 清除旧 staged blob；Doom原件仅在 `origin/master` 文件 hash/内容确认后移除；任何冲突不使用 reset覆盖。
- PR失败或未合并时保留本任务 worktree、分支与所有原件，不声明完成、不进入 destructive cleanup。

## 8. Observability

- Git：`status --porcelain=v2 --branch`、`rev-list --left-right --count`、`worktree list --porcelain`、`branch -vv`。
- PR：`gh pr view/list/checks` 的 state、head/base oid、merge commit和 required checks结果。
- 等价性：combined `git diff ... | git patch-id --stable`、reachability与候选 diff。
- 占用：删除前再次运行 `lsof +D <worktree>` 和 `lsof -- acorn_password`，只记录是否为空。
- 安全：候选 diff secret-marker扫描、`git ls-files --error-unmatch acorn_password` 负例。

## 9. Security & Privacy

- `acorn_password` 内容永不被读取、hash、打印或复制；仅记录 metadata和负向 Git检查。
- 不输出 token、cookie、private key、OTP、pairing URL或 age明文。
- 候选 Doom/审计文档仅包含公开 commit/PR、路径、状态与脱敏判断。
- 删除秘密样文件优先使用 Trash；若 Trash不可用则停止并报告，不回退到 broad `rm`。

## 10. Open Questions

无阻塞问题。独立 reviewer 可对任一 disposition提出 blocking finding；在其 PASS 前不执行删除。

## 11. References

- `plan.md`
- `docs/research.md`
- `origin/master:.legion/wiki/tasks/aliyun-acorn-ecs-deploy.md`
- `origin/master:.legion/tasks/constx-azar-native-auth-mini/log.md`
- `https://github.com/Thrimbda/doom-c1/pull/1`
- `https://github.com/Thrimbda/dotfiles/pull/139`
- `https://github.com/Thrimbda/dotfiles/pull/210`
- `https://github.com/Thrimbda/dotfiles/pull/211`
- `https://github.com/Thrimbda/dotfiles/pull/216`
