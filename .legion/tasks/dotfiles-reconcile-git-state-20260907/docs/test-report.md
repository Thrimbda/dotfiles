# Test Report: Dotfiles Git State Reconciliation (Pre-delivery)

## 验证范围与方法

本轮验证只判断 preservation candidate 是否可进入 review/PR，以及 merge 后 cleanup 的前置证据是否充分；不执行任何原件、秘密样文件、旧 worktree 或 branch cleanup。机械检查的脱敏原始输出保存在 `docs/evidence/pre-delivery-git-audit.txt`。最终主工作区一致性 C4 必须在 preservation PR 合并并完成精确清理后重跑，不能由本报告提前代替。

## Claim Register

| Claim | 性质 / 时机 / 门槛 | domain / capability / method | criticality / risk-if-wrong / policy / owner | 状态 | 证据与结论 |
| --- | --- | --- | --- | --- | --- |
| C1：删除前每个 worktree/branch/local diff 已被远端覆盖或已转移保留 | objective / now / routine | `git-state` / PR、对象图、patch 等价、dirty 与占用审计 / PR API + reachability + combined patch-id + inventory + `lsof` | high / 丢失独有工作 / block-stage / verifier | PASS（pre-delivery safety） | #210/#211/#216/#139 均为 MERGED，combined PR diff 与 squash merge patch-id一致且 merge在 `origin/master`；RustDesk checkout HEAD 是 #139 head ancestor。Doom 9+1 文件已复制；Constx 独有事故已提炼。四旧 worktree 在 `2026-09-07T09:50:16Z` 的 `lsof +D` 均为 exit 1、空输出。真正删除前仍必须按 RFC 即时重跑；任一漂移即停止。 |
| C2：候选提交不含秘密或秘密派生值 | objective / now / routine | `secret-hygiene` / 候选内容与 Git index 负向审计 / diff marker scan + `git ls-files` | high / 凭据泄露 / block-merge / verifier | PASS | 20 文件实现候选的高置信 private-key/token marker扫描无命中，candidate/index不跟踪 `acorn_password`；本报告与 raw evidence又经独立全文审阅，未含秘密值。该文件只检查 metadata，内容从未读取。 |
| C3：逐项保留/丢弃符合 durable truth、独有性、可复用性、时效性与可逆性 | judgmental / not-applicable / routine | `repository-knowledge` / 逐资产价值判断 / 当前 wiki、PR终态、独有性和可逆性矩阵 | high / 删除有价值证据或恢复过期真相 / block-stage / user（decision owner）与 RFC reviewer | RECOMMENDATION | 推荐保留 Doom 完成证据与 Constx failure shield；丢弃 Aliyun重复 contract、Constx过期状态、Nix cache和明文秘密样文件。事实与价值取舍见下节；这不是 objective PASS。 |
| C4：最终主工作区与最新远端完全一致 | formal / plan预注册为 now，但本轮按 RFC milestones 4–6 延后到 delivery/cleanup 后 / routine | `git-state` / 终态一致性证明 / final fetch + branch/upstream + rev-list + status + worktree list | high / 虚假完成或错误清理 / block-stage（终态门） / lifecycle verifier | DEFERRED | 当前主工作区为 `master`、`0 12` 且仍有原件/旧 worktree，不能 PASS。RFC 作为设计真源明确把该检查排在 merge与cleanup后，因此完整延后协议允许本次 **pre-delivery** Verdict PASS；它绝不允许任务完成声明，触发后必须重新执行 `verify-change -> review-change`。 |

## 执行记录与结果

### Candidate scope / whitespace

- `git status --porcelain=v2 --branch`：候选 worktree从 `origin/master` 建立；采集时因远端推进为 `+0 -1`，push前必须 fetch/rebase。
- `git diff --check`：exit 0。
- raw snapshot覆盖 20 个实现文件：Doom raw/wiki evidence、reconciliation task evidence，以及 4 个 wiki页面修改；没有 Nix/host/runtime代码改动。本报告与 raw evidence 是 snapshot 后新增的验证 artifact，交付前必须对包含二者的最终候选再次运行 `git diff --check` 与秘密扫描。

### Doom preservation

- 源与候选均为 9 个 raw task文件；wiki task存在且非空。
- 8 个 raw文件与 wiki task SHA-256逐字节相等；`tasks.md` 仅规范化两处行尾空格，去除行尾空格后内容相等。
- `Thrimbda/doom-c1#1` 当前 state `MERGED`，merge `507d5924...`；该 merge仍是当前 Doom `origin/master` ancestor。
- Wiki index link、maintenance heading、archive pattern均各出现一次，目标文档存在。

### Merged worktree equivalence

- #210 patch-id `657e12c9...`；#211 `03130612...`；#216 `a519b193...`；#139 `3613f075...`。每组 head/base combined diff 与 squash merge diff相同，merge均在当前 `origin/master`。
- RustDesk detached HEAD `3db55d1c...` 是 #139 head `57e8dc91...` ancestor。
- 四旧 worktree的 tracked/untracked inventory已记录；当前 `lsof +D` 均为 exit 1 / 0 lines。该时点证据不替代 merge后即时复核。

### Supersession / value

- `Thrimbda/dotfiles#88` 当前为 MERGED；当前 wiki同时记录 QCOW2 build/ECS runbook和后续 canonical `acorn` rename，因此 `aliyun-nixos-ecs-deploy` 是过期重复草案。
- 当前 `constx-azar-native-auth-mini` 记录 delivery complete及 D3/D4用户-owned deferred决定，覆盖旧 rollout的 `FAIL / decide` 状态。
- 新 `wiki/patterns.md` 精确保留旧 dirty evidence中尚未覆盖的 failure shield：archive-based remote Nix deployment必须补齐 ignored encrypted agenix/helper source roots，验证路径，并在 activation失败时先回滚前一 generation；不复制 record ID、IP或时点运行态。

### Secret hygiene

- `acorn_password` 仅记录 path、mode `0600`、size 9、mtime与 `lsof` 空结果；未读取、hash或输出内容。
- `git ls-files --error-unmatch acorn_password` 在 candidate中 exit 1，即未跟踪。
- 候选 task/wiki文件的高置信 private-key、AWS/GitHub/OpenAI token marker扫描无命中。

## Verifier / Authority / Provenance

- Domain verifier：不适用。Claims使用 Git对象图、GitHub PR API、filesystem metadata、`lsof` 与静态内容检查，均属于 routine工程验证。
- Authority evidence：不适用。GitHub PR state/OID 与当前 Git remote refs是代码交付终态的直接来源；不评价生产运行态。
- 原始证据：`docs/evidence/pre-delivery-git-audit.txt`，包含采集时间、关键命令结果、exit status、OID、patch-id、文件hash与负向检查；不含秘密内容。
- 验证独立性：raw command bundle由实现侧采集，作者独立性为 low；未参与实现的 verifier 已逐项审计 raw evidence → claim 映射，判断独立性为 high。C1/C2对采集时点的置信度 high，状态漂移后失效；C3为 judgmental，置信度 medium且只返回 RECOMMENDATION；C4没有当前终态证据，只能 DEFERRED。

## Judgmental Protocol: C3

- 可选方案：A 全部保留；B 全部丢弃；C 选择性保留并在 merge recovery point 后精确清理。
- 判断标准与事实依据：独有性、当前真相、跨任务复用价值、时效性与可逆性；Doom 9+1副本、PR/patch-id、Aliyun current wiki、Constx后续 user-deferred completion和旧 worktree inventory提供事实层。
- 价值取舍与可逆性：C避免把旧 `FAIL / decide` 恢复为当前真相，也避免丢失唯一事故模式；merge前保留全部原件，merge后 Aliyun草案与秘密样文件进入 Trash，降低不可逆性。
- 最强反方理由：完整保留旧 Constx rollout可最大化历史可审计性；但其过期状态与时点运行态会污染当前真相，且独有 failure shield已被最小提炼。
- 推荐与 decision owner：推荐 Option C；用户是 decision owner，原请求已授权按提交价值处置，本轮未发现需要新增取舍的问题。

## Deferred Protocol: C4 Final Reconciliation

- `trigger`: preservation PR 已 squash merge，随后 `git fetch origin --prune` 可观察到 merge进入 `origin/master`。
- `owner`: 当前 lifecycle 编排器。
- `method`: 先证明 `origin/master` 包含 Doom task/wiki与 archive failure shield；即时重跑所有删除目标的 PR/OID、dirty inventory、`lsof`与 secret未跟踪负例；按 RFC精确 Trash/remove/restore；删除本任务 worktree/branch；运行安全 refresh；再次 fetch并检查 branch、rev-list、status、worktree list。
- `requiredData`:
  - `name`: merged preservation PR；`source`: GitHub PR API与本地 `origin/master`；`acceptance`: state `MERGED` 且 merge进入 `origin/master`。
  - `name`: deletion-time safety refresh；`source`: Git/PR/dirty inventory/`lsof`/secret负例；`acceptance`: 与 pre-delivery disposition一致且无占用，否则停止。
  - `name`: final Git state；`source`: final fetch、branch、rev-list、status、worktree list；`acceptance`: `master`、`HEAD...origin/master = 0 0`、clean status、仅主 worktree。
- `currentRisk`: 远端、dirty inventory或进程占用可能在 PR期间漂移。
- `mitigation`: merge前不删除任何原件；merge后每个目标即时复核，失败即保留该目标并停止。
- `failureImpact`: 误删独有内容、删除仍被占用的 checkout，或在本地未真正一致时虚假声明完成。
- `rollback`: Aliyun草案与秘密样文件只移入系统 Trash；PR/远端未形成恢复点或任一复核失败时保持原件/worktree不动；不使用 broad reset/clean。
- `stopCondition`: PR未合并、远端不含保留项、任一目标出现新独有内容/占用、Trash不可用、refresh不能 fast-forward，均停止并不得声明完成。
- `successorTask`: restore `dotfiles-reconcile-git-state-20260907` at post-delivery `verify-change`, then run `review-change`;旧报告保持历史证据。
- `onPass.nextAction`: 写入新的 post-delivery test report与review，随后完成 lifecycle。
- `onPass.conclusionUpdate`: 新报告将 C4更新为 PASS；不回写本报告的 DEFERRED历史状态。
- `onFail.nextAction`: 保留未处理目标，记录 blocker与恢复条件，不强制对齐。
- `onFail.conclusionUpdate`: 新报告将 C4更新为 FAIL，任务保持未完成。

## 失败、跳过与残余不确定性

- 预交付采集后 `origin/master` 已前进 1 个提交；这是预期漂移，push前必须 rebase，且最终 C4必须使用新一次 fetch。
- 没有把历史文档中的服务 active、DNS、浏览器或生产E2E表述当作当前运行态证据。
- 未执行任何 cleanup；本报告只批准 candidate进入独立 review，不批准跳过 merge-before-cleanup门。
- snapshot后的两个验证 artifact尚未获得一次新的整仓 `git diff --check`/marker scan；交付前必须补跑，失败即退回修正文档。

## Verdict

PASS

## 会话注意力摘要

- 阶段：verify-change（pre-delivery）
- 阶段结论：PASS
- 注意力等级：review
- 判断变化：Doom保留内容、四个merged PR的squash等价、secret负例与Constx事故语义覆盖均有可重算证据；C4明确保留为post-merge强制门。
- 关键发现：
  1. C1/C2通过；删除安全仍以merge后即时复核为时效条件。
  2. C3为有依据的RECOMMENDATION：保留Doom与failure shield，丢弃重复/过期/缓存/秘密样内容。
  3. C4当前为DEFERRED，不得据此声明主工作区已一致或任务完成。
- 阻塞项：无；本阶段可进入review-change与PR准备，但复核落盘前禁止 auto-merge、merge和cleanup。
- 残余风险：远端、dirty inventory和进程占用可能漂移；由Deferred Protocol的即时重查与失败停止控制。
- 人类动作：唯一动作是复核 C3处置建议、C4延后协议及“最终候选需补跑两项检查”的限制；复核落盘前停止 auto-merge、merge与cleanup。
- 自动下一步：独立`review-change`并准备PR；复核落盘且最终候选检查通过后才可merge，随后按Deferred Protocol执行cleanup并重跑C4。
- 完整证据：
  - `.legion/tasks/dotfiles-reconcile-git-state-20260907/docs/evidence/pre-delivery-git-audit.txt`
  - `.legion/tasks/dotfiles-reconcile-git-state-20260907/docs/test-report.md`
  - `.legion/tasks/dotfiles-reconcile-git-state-20260907/docs/review-rfc.md`
