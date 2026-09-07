# 变更审查：Dotfiles Git State Reconciliation（pre-delivery）

审查身份：独立 `review-change` reviewer；未参与本轮 preservation 实现。

审查范围：只读复核 `plan.md`、`docs/rfc.md`、`docs/review-rfc.md`、实际候选 diff、`docs/test-report.md` 与 `docs/evidence/pre-delivery-git-audit.txt`。未修改实现、未执行 cleanup，且未读取、hash 或输出 `acorn_password` 内容；本文件是唯一写入。

## Verdict

PASS

该 PASS 仅表示 preservation candidate 可进入 commit/PR 准备，不表示允许 merge、cleanup 或任务完成。最终候选的 C2 证据缺口构成 `block-merge`，C4 仍是完整的 post-merge `DEFERRED` 终态门。

## Scope / correctness / maintainability

- 实际实现 snapshot 为 20 个文件：9 个 Doom raw task 文件、Doom wiki task、当前 reconciliation task 文档及 4 个 wiki 页面修改；没有 Nix、host、runtime、部署或秘密内容变更，符合 contract 的文档恢复与知识提炼范围。
- Doom 内容由 author-captured SHA-256/equivalence bundle支持：8 个 raw 文件与 wiki task逐字节相同，`tasks.md` 只移除两处行尾空格且 normalized content 相同；Doom PR #1 merge `507d5924...` 仍是当前 Doom `origin/master` ancestor。该证据足以支持 preservation correctness，不把历史运行态当成当前运行态。
- Aliyun、Constx、RustDesk 与三个 clean/merged worktree 的 disposition 与 RFC 一致。四组 squash patch-id、merge reachability、RustDesk ancestor、dirty inventory及采集时 `lsof`结果均映射到 C1；真正删除前仍由 RFC 的即时复核门重新判定，时点证据不会被当成永久事实。
- 新增 Constx pattern准确收敛 `git archive` 的 source-completeness 故障：枚举 ignored encrypted agenix/helper source roots、只复制必要密文/源路径、不解密、切换前验证、失败先回前一 generation再修正重试。它未复制旧 `FAIL / decide`、IP、record ID或时点运行态，也未声称 build success 等于 activation success。
- Pattern 的“复制 encrypted source roots”应与同一 wiki 已有的 target-recipient/decryptability 规则共同阅读；二者不冲突。可选地以后加交叉引用，但当前文本已限定 required roots、no plaintext 与 rollback，不构成安全或维护 blocker。

## Claim 重新聚合

| Claim | reviewer 状态 | 复核结论 |
| --- | --- | --- |
| C1 | PASS（pre-delivery safety） | PR/OID、reachability、patch-id、Doom transfer、Constx semantic extraction、dirty inventory 与 merge-before-cleanup 门形成可重算链。证据失效条件是远端、dirty state或进程占用漂移；RFC要求删除前即时重跑，失败即停止。 |
| C2 | INCONCLUSIVE（`block-merge`） | 高置信 secret scan 与 `git diff --check` exit 0只覆盖 20-file implementation snapshot。随后新增 `pre-delivery-git-audit.txt`、`test-report.md`，本审查又新增本文件；人工阅读未见秘密值，但 reviewer不能替 verifier补造最终候选机械证据。必须对 finalized staged diff重跑两项检查后才能恢复 PASS。 |
| C3 | RECOMMENDATION | Option C完整列出 A/B/C、事实标准、可逆性和最强反方。用户原请求明确委托 agent 判断提交价值并处置，无新增互斥选择或风险接受问题，因此不升级为 `decide`；状态仍保持 judgmental `RECOMMENDATION`，不伪装成 objective PASS。 |
| C4 | DEFERRED | 当前主工作区不是终态，不能 PASS。RFC明确把触发放在 preservation PR merge与精确 cleanup 后；test report记录 owner、trigger、method、required data、stop condition、successor task及 onPass/onFail，因此可与本阶段 PASS共存，但至少保持 `review` attention并禁止完成声明。 |

## 验证与 provenance 充分性

- Raw locator 可读：`docs/evidence/pre-delivery-git-audit.txt` 记录采集时间、candidate status、文件集合、hash/equivalence、PR/OID/patch-id、worktree inventory、`lsof` exit/line count、秘密负例与当前非终态。`docs/test-report.md` 将这些段落逐项映射到 C1–C4，并明确 author-captured bundle 的独立性为 low、独立 verifier判断为 high。
- 本审查没有把 author-captured 数据重新描述为本轮 live rerun。其置信度仅限 `2026-09-07T09:50:16Z` snapshot；最终删除依赖新证据。
- Domain verifier 不适用：本任务只涉及 routine Git对象图、GitHub PR、filesystem metadata、静态文档和进程打开文件检查。Authority evidence亦不适用；PR API/OID是代码交付直接事实，不是外部专业签署。
- `C4` deferred protocol完整且 contract/RFC 明确允许其发生在 delivery 后。它允许 commit/push/PR/checks准备；当前 `review` 门禁止 auto-merge、merge与cleanup，待最终 C2复核和唯一人类复核落盘后，merge才可作为 C4 trigger发生。C4本身始终阻止任务完成声明，直到 post-delivery `verify-change -> review-change` 得到 PASS。

## Security lens

适用：候选处理秘密样文件、encrypted agenix source与未来 destructive cleanup。

- `acorn_password` 只以路径、mode、size、mtime、Git未跟踪负例和 `lsof`空结果出现；没有内容、hash、派生值或暂存动作。未来仅在 merge recovery point与即时无占用/未跟踪复核后移入系统 Trash，Trash不可用即停止。
- 20-file snapshot 的高置信 private-key/AWS/GitHub/OpenAI token marker扫描无命中；候选文档中的 `password`、`token`、`secret` 均为策略文字或不透明路径说明。由于验证 artifacts 与本 review是 snapshot 后新增，最终 staged diff仍必须重扫，不能从人工阅读推导 C2 PASS。
- Constx pattern要求密文不解密、只复制 required source roots并先验证路径；同一 wiki另有目标 recipient/decryptability约束。未发现 plaintext、credential transport、permission widening或把秘密加入 Git的指令。
- 没有执行部署、远端写入、branch删除、worktree移除、stash、reset或clean，merge-before-cleanup恢复点仍完整。

## Blocking findings

没有 stage-blocking implementation finding。

### M1：最终候选缺少 snapshot 后的 whitespace 与高置信 secret 复核（block-merge）

- 定位：`docs/test-report.md` 的 Candidate scope / whitespace、失败/跳过章节；实际 status 中 `docs/evidence/pre-delivery-git-audit.txt` 与 `docs/test-report.md` 为 snapshot后新增，本文件随后新增。
- 原因：现有 exit 0 / no-hit不能证明未被其输入覆盖的文件；C2适用于实际提交候选而不是早期子集。
- 影响：不阻止 commit/push/PR/checks准备，但在 finalized staged diff得到同方法的 `git diff --check` exit 0 与 label-only高置信 secret scan no-hit前，C2只能 `INCONCLUSIVE`，不得 merge或cleanup。
- 最小修复：由 verifier在所有交付 artifacts（含本审查）固定后，对完整 staged diff重跑并将命令、范围、exit/status和脱敏结果追加到 repo内 evidence/test report；reviewer不代跑或代填。若任一失败，回到对应文档修正并重新验证。

## 可选建议

- 在最终 evidence 中同时记录 rebase 后 base OID与最终文件清单，避免当前 `origin/master` 已前进造成 snapshot范围歧义。
- 后续若扩写 archive pattern，可显式链接既有 agenix target-recipient/decryptability规则；当前无需为此改动候选。

## 会话注意力摘要

- 阶段：review-change（pre-delivery）
- 阶段结论：PASS
- 注意力等级：review
- 判断变化：实现与 C1/C3/C4 设计一致，但 C2 的机械 PASS只覆盖20-file snapshot；新增 evidence/test/review artifacts使最终候选暂为 `INCONCLUSIVE / block-merge`。
- 关键发现：
  1. C1 pre-delivery safety通过；所有 destructive cleanup仍受 merge recovery point和删除前即时复核约束。
  2. C3保持 user-delegated `RECOMMENDATION`，无新决定；Constx pattern准确且未恢复过期状态。
  3. C4完整 `DEFERRED` 允许PR准备，但在 post-delivery复验前禁止完成声明。
- 阻塞项：M1阻塞 auto-merge、merge与cleanup；finalized staged diff必须补跑 whitespace与高置信 secret检查。
- 残余风险：远端、dirty inventory和进程占用会漂移；C4仍未触发，最终 `0 0 + clean + single worktree`尚未证明。
- 人类动作：复核最终 pre-merge evidence bundle（必须包含M1补查结果、C3处置与C4延后边界）并将接受记录落盘。
- 自动下一步：可准备commit/push/PR/checks；由 verifier先关闭M1，再等待上述唯一人类复核；此前停止auto-merge、merge与cleanup。merge后按C4协议重跑 `verify-change -> review-change`。
- 完整证据：
  - `.legion/tasks/dotfiles-reconcile-git-state-20260907/docs/review-change.md`
  - `.legion/tasks/dotfiles-reconcile-git-state-20260907/docs/test-report.md`
  - `.legion/tasks/dotfiles-reconcile-git-state-20260907/docs/evidence/pre-delivery-git-audit.txt`
