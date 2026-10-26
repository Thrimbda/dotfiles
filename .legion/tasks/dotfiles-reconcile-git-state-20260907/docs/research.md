# Research: Dotfiles Git State Reconciliation

## 1. Problem Restatement

主工作区 `master` 在 2026-09-07 fetch 后相对 `origin/master` 为 `0 11`，并混有 staged、untracked、秘密样文件和四个历史 linked worktree。目标是在不误删独有工作的前提下，选择性保留、交付和清理，最终与最新远端一致。

## 2. Current Inventory

| 资产 | 当前状态 | 远端 / PR 证据 | 初步价值判断 |
| --- | --- | --- | --- |
| staged `.legion/wiki/{index,log,maintenance}.md` | 只新增 Doom Org/Norang 导航、完成日志和后续维护项 | `origin/master` 无该任务摘要；Doom 仓库 PR #1 已于 2026-07-09 合并 | 保留；需在最新 wiki 上重放，不能覆盖远端新增内容 |
| untracked `.legion/tasks/doom-org-norang-minimal/**` 与 wiki task | 完整 contract、design-lite、验证、review、walkthrough 和 PR 终态 | `Thrimbda/doom-c1#1` MERGED，merge `507d5924...`；当前 Doom `master...origin/master` 为 `0 0` | 保留；属于真实完成任务的 dotfiles 侧证据与 durable summary |
| untracked `.legion/tasks/aliyun-nixos-ecs-deploy/**` | 仅 contract/log/checklist，未进入实现 | `origin/master` 已有完成的 `aliyun-acorn-ecs-deploy`：PR #88、QCOW2 build、ECS runbook、wiki patterns；后续 `acorn-aliyun-host-rename` 又替换旧 host identity | 丢弃；目标与事实均被完成任务覆盖，且路径/host 名称已过期 |
| untracked `acorn_password` | owner-only、9 bytes、ASCII；未读取内容；无 open handle | 既有 `acorn-cybion-ingress` review 已把它标为仓库根目录的无关明文凭据并建议另行处理 | 丢弃到 Trash；安全负债，不可提交 |
| Constx public-deployment worktree | PR #210 merge commit checkout；2 个 tracked 修改 + 2 个新证据文档 | #210 patch-id 与 squash merge一致；后续 `constx-azar-native-auth-mini` 已记录用户决定 D3/D4 deferred，并以 PR #212/#217 完成交付 | 不保留整份过期 `FAIL / decide`；先提炼其中尚未覆盖的 archive activation/rollback 事故模式到 wiki，再于该提炼 PR 合并后丢弃 dirty 增量 |
| Constx signout worktree | clean，HEAD 为 #216 head | #216 MERGED；head/base diff 与 squash merge patch-id 都是 `a519b193...` | 清理 worktree/本地 branch |
| Constx run-environment worktree | clean，HEAD 为 #211 head | #211 MERGED；patch-id 都是 `03130612...` | 清理 worktree/本地 branch |
| RustDesk detached worktree | tracked clean，仅 `.cache/nix/**` | worktree HEAD 是 #139 head 的 ancestor；#139 MERGED 且 merge在 `origin/master`；PR patch-id 都是 `3613f075...` | 丢弃重建型 cache并清理 worktree |

所有四个历史 worktree 的 `lsof +D <path>` 均无输出；未观察到进程持有其文件或 cwd。`acorn_password` 同样无 open handle。

## 3. Existing Conventions and Current Truth

- 修改型 Legion 工作必须从最新 `origin/master` 建立仓库内隔离 worktree，不直接提交主分支。
- `.legion/wiki/**` 是当前综合真相，raw task docs 不得把过期状态提升为当前结论。
- `origin/master:.legion/wiki/tasks/aliyun-acorn-ecs-deploy.md` 与 `patterns.md` 已记录 ECS custom image build/import/runbook 和 UEFI/cleanup 模式。
- `origin/master:.legion/tasks/constx-azar-native-auth-mini/{log.md,tasks.md,docs/test-report.md,docs/review-change.md}` 是后续权威记录：D3/D4 由用户决定 deferred，delivery 已完成；不得恢复成旧 `FAIL / decide`。
- `origin/master:.legion/wiki/patterns.md` 已记录 Git-backed flake 对 untracked/new path 的可见性风险与秘密文件不得暂存的边界。
- Constx dirty evidence 还包含现有 wiki 和后续任务未完整覆盖的独有事故事实：`git archive` 源遗漏 ignored encrypted agenix paths 与被引用的 zsh helper source root，首次 generation 39 activation 失败后立即回滚 generation 38；补齐加密 source roots 并验证路径后，第二次 activation 成功且未读取 plaintext secret。旧 `FAIL / decide` 状态不可保留，但该 archive-based remote deployment failure shield 应提炼到 `wiki/patterns.md`。

## 4. Constraints and Non-goals

- 只能从候选提交 diff 扫描秘密；不得读取 `acorn_password` 内容。
- 删除前必须完成 PR/patch/reachability 和 process ownership 证据。
- 不把此次仓库整理扩展为任何部署、canary、凭据轮换或远端 feature branch 批量删除。
- 保留项必须先复制到最新基线 worktree并验证，随后才清理主工作区原件。

## 5. Risks and Pitfalls

- `branch --merged` 无法识别 squash merge；必须用 PR head/base 与 merge commit 的 combined patch-id，或 remote reachability。
- staged wiki 基于旧 `master`，直接 restore/checkout 会覆盖 11 个远端提交中的 wiki 更新。
- Constx dirty 文档包含采集时为真的运行态，但现在的状态机已被后续任务替代；原样提交会制造冲突真相，整份删除又会丢失独有 archive/rollback 事故模式，必须先做语义提炼。
- `git worktree remove --force` 会删除 dirty/untracked 内容，因此只可在 disposition 和独立 review 通过后使用。

## 6. Unknowns

- 无阻塞 unknown。Git/PR 覆盖、任务真相、秘密 metadata 与 open-handle 检查均有当前证据；内容价值属于明确的 judgmental recommendation，交由独立 RFC review 对抗检查。

## 7. References

- Doom PR: `https://github.com/Thrimbda/doom-c1/pull/1`
- Dotfiles PRs: `#139`, `#210`, `#211`, `#216`
- `.legion/wiki/tasks/aliyun-acorn-ecs-deploy.md`
- `.legion/wiki/tasks/acorn-aliyun-host-rename.md`
- `.legion/tasks/constx-azar-native-auth-mini/log.md`
- `.legion/tasks/constx-azar-native-auth-mini/docs/test-report.md`
- `.legion/wiki/patterns.md`
