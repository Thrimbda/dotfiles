# RFC 审查（round 2）：Selective Git-State Reconciliation

审查范围：独立重读更新后的 `docs/research.md` 与 `docs/rfc.md`，复核 round 1 B1、Option C 的可实施性、可验证性与可回滚性。未读取 `acorn_password` 内容；本文件是唯一写入。

## Verdict

PASS

## Round 1 B1 复核

### B1 已关闭：Constx 独有事故事实已有最小保留单元和 merge-before-cleanup 门

Round 1 判定为 FAIL，是因为旧设计把 Constx dirty evidence 整体视为过期，并允许在独有的 archive activation/rollback 事故尚未形成 durable recovery point 前移除 dirty worktree。

更新后的 research 已把事实与旧状态分开：后续 `constx-azar-native-auth-mini` 仍是 `FAIL / decide` 与运行终态的权威来源，不原样保留旧 report；唯一未被覆盖的 durable truth 被明确识别为 `git archive` 遗漏 ignored encrypted agenix paths 和被引用的 zsh helper source root、首次 activation 失败后立即回滚、补齐加密 source roots 并验证路径后重试成功，且不读取 plaintext secret。

RFC 4.1 将其收敛为一条脱敏 wiki pattern，明确排除旧 verdict、时点运行态、record ID、IP 与完整 rollout report；4.2、Milestones 与 Rollback 又把 Constx dirty worktree、Doom 原件、Aliyun 草案、`acorn_password` 和其它旧 worktree 的清理统一推迟到 preservation PR 已 squash merge，且重新 fetch 证明 `origin/master` 已包含恢复点之后。PR 未合并或任一实时复核失败时，所有原件与旧 worktree继续保留。round 1 的不可验证、不可回滚路径因此消失。

## Option C 设计判断

### 可实施

- 保留动作已缩成两个有界单元：精确重放 Doom 文档/wiki additions，以及向最新 `wiki/patterns.md` 提炼一条 Constx failure shield；两者都不要求恢复历史部署、读取秘密或复制旧状态报告。
- Aliyun 草案、过期 Constx 状态、RustDesk cache 与秘密样文件均有逐项 disposition；worktree 与本地 branch 只做精确、Git-aware cleanup，不扩展到远端 branch 或其它仓库。

### 可验证

- C1 使用 PR state/OID、reachability、base-to-head 与 squash-merge patch-id、dirty inventory 和删除前即时 `lsof`；该组合可以避免 squash ancestry 假阴性，并覆盖 committed、tracked dirty 与 untracked 三类状态。
- C2 只扫描候选 diff和路径 metadata，以 `git ls-files --error-unmatch acorn_password` 提供负路径；不需要也不允许读取秘密内容。
- C3 保持 `RECOMMENDATION`，事实、价值标准、最强反方方案和可逆性已通过 Options/资产表展开；原请求已授权在无提交价值时精确丢弃，没有遗留互斥决定。
- C4 的 final fetch、branch/upstream、`0 0`、clean status 与 single-worktree 判定是可重算的 formal gate。

### 可回滚

- Preserve、verification、review 和 merge 期间不触碰主工作区原件、秘密样文件或旧 worktree；本任务 worktree/branch与原件共同构成 merge 前恢复点。
- merge 后才进入 disposal；Aliyun 与 `acorn_password` 进入系统 Trash，tracked worktree内容可由已核对 PR/merge恢复，Constx独有语义由已合并 wiki pattern恢复，Nix cache可重建。
- 任一 PR/OID、dirty inventory、占用或远端包含检查失败即保留对应目标并停止，未设计 broad reset、clean、stash 或递归删除回退。

## Blocking findings

无。

## 非阻塞建议

- `docs/rfc.md` 4.3 的“设计审查通过后移除 worktree”应按 Executive Summary、Milestones 与 Rollback 的更强全局门解释为“设计审查通过且 delivery recovery point 已验证后”；实现与 test report 宜使用后者原文，避免脱离上下文误读。
- 删除前的 `lsof` 证据除“是否为空”外，宜保留 exact path、采集时间、stdout/stderr 与 exit status，以区分无占用和命令失败；这不改变 RFC 已明确的即时复核与失败停止门。

## 会话注意力摘要

- 阶段：review-rfc
- 阶段结论：PASS
- 注意力等级：skim
- 判断变化：round 1 B1 已关闭；Option C 现在具备 Constx 独有事故的最小 durable 保留单元，并把所有 destructive cleanup 推迟到 squash merge 与 `origin/master` 恢复点验证之后。
- 关键发现：
  1. Constx 仅提炼 archive/agenix/zsh source-root failure shield，不恢复过期 `FAIL / decide` 或时点运行态。
  2. PR 未合并、远端未包含保留项或任一即时复核失败时，原件与旧 worktree均保留，rollback 边界闭合。
  3. Patch-id/reachability、dirty inventory、秘密负例与删除前即时占用检查足以支撑后续 C1/C2/C4 验证。
- 阻塞项：无。
- 残余风险：PR/OID 与进程占用会随时间漂移；RFC 已要求在 disposal 前实时重查，test evidence 仍应保留命令退出状态。
- 人类动作：无动作。
- 自动下一步：交回 `legion-workflow` 进入有界实现与验证；merge 前只创建 preservation candidate，不执行任何原件或旧 worktree cleanup。
- 完整证据：
  - `.legion/tasks/dotfiles-reconcile-git-state-20260907/docs/review-rfc.md`
  - `.legion/tasks/dotfiles-reconcile-git-state-20260907/docs/research.md`
  - `.legion/tasks/dotfiles-reconcile-git-state-20260907/docs/rfc.md`
