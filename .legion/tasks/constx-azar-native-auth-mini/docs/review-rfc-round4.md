# RFC 审查（round 4）：Azar 上 Const X 原生 Auth Mini 部署

审查范围严格限于当前部署任务的 `plan.md`、`tasks.md`、`log.md`、`docs/research.md`、`docs/rfc.md` 与前三轮审查。本轮仅复核 round 3 所要求的 final merge -> Axiom build -> Azar binary -> G1 `ExecStart` provenance gate；不修改实现、计划、状态或日志。

## Verdict

FAIL

## 本轮独立判断

PR #82 的最终 SHA 已被固定为 `92112facdb30a1a3a02e0a31fadcf3ff4a6ea379`，RFC 也新增了 manifest、Azar hash 复算、G0 显式 binary 路径及 G1 hash 对照。这比 round 3 前的文字性“最终再核对”更接近正确方向。

但这仍不是完整、可重算的 fail-closed gate：它没有把 final Git object 与 C3 source test evidence 的可复用或重跑规则绑定，也没有把 manifest 中的 Azar binary 唯一地绑定到 G1 **实际运行**的 `constxd` executable。因而两个缺口均可在所有现有 manifest 字段“看似一致”时存在，G0 mutation 或 G2 cutover 不应获准。

## Findings

### F1：final merge SHA 仍未与 C3 source evidence 形成可机械判定的入场券

> [REVIEW:blocking] RFC 仅要求 Axiom checkout 的 `HEAD` 等于 final SHA，并称 final tree 中的 test report 可读、source SHA/binary SHA/build log/test locator “相互对应”。它没有规定：应比较哪一组 final blobs 与候选 C3 baseline、比较结果保存在哪里；或者在任何差异/不可比较/证据不可读时，必须在 final SHA checkout 重跑哪些 C3 tests、记录何种命令/exit/raw output。故“final tree 里有 report”和手工填写的 manifest 仍可满足当前文字，却不能证明被构建的 final object 受 C3 行为证据覆盖。
>
> [STATUS:open]

定位：`docs/rfc.md:80-108`。

影响：G0 gateway 可以继续保护公网入口，却不能阻止一个未被最终 source evidence 覆盖的 resolver/config writer 首次写入私有运行时状态；Azar same-binary `--check` 也不能追溯或恢复已被错误 mutation 的 non-auth state。这正是 round 3 已识别的 state-preservation 与 rollback 可验证性风险。

最小修复：将 final-release-provenance 变成有唯一产物 locator 的硬 gate。它必须固定 `FINAL_MERGE_SHA` 与候选 baseline，列出 configure-auth implementation、CLI、process/config tests、test report 和 C3 raw evidence 的精确 Git blob 比较范围与结果；仅当全部一致时才复用候选 evidence。任何 blob 差异、baseline 不可比较、证据缺失或读取失败，都必须在 `FINAL_MERGE_SHA` 的 clean checkout 重跑预注册 C3 tests，保存脱敏 command、exit status、raw output 与 source/object hash。没有这份记录，停止于 G0，不得 `configure-auth`、G1 或 G2。

### F2：Azar binary 到 G1 `ExecStart` 的核验仍停留在 rendered 配置，未证明实际进程

> [REVIEW:blocking] RFC 要求 G1 的“rendered `constxd.service ExecStart` 和本地 SHA-256”再次匹配 manifest，但未定义如何从 systemd 的实际 `ExecStart` 解析出唯一 executable，也未要求核对 active `MainPID` 的实际 executable。rendered unit、wrapper/symlink、后续 exec 或旧 generation 残留都可能使渲染文本和一个单独计算的文件 hash 同时成立，而运行中的 `constxd` 并非 manifest 的 `azar_release_binary`。
>
> [STATUS:open]

定位：`docs/rfc.md:93-100,112-126`。

影响：G1 是证明目标 native verifier 已在 gateway 保护下运行的关键状态。若其 active process 无法被机械地绑定到经过 Axiom/Azar hash 验证的 binary，loopback 401 不能证明 audience verifier 来自 final release，G1 也不能安全放行 G2；G2 -> G1 -> G0 rollback 的“同一目标 binary”前提随之不可验证。

最小修复：在 manifest 中规定唯一、无 wrapper 歧义的 target executable，并在 G1 activation 后以实际 systemd state（而不是仅 rendered config）验证：读取 `constxd.service` 的 effective `ExecStart`，解析其最终 executable；读取 active `MainPID` 的 executable；两者的 canonical path 和 SHA-256 都必须等于 manifest 的 `azar_release_binary` / `binary_sha256`，并保存脱敏输出 locator。任何 path、resolver、PID、hash 或 unit-state 不一致/不可读，必须保持或回到 G0 gateway，禁止 G2；不得把 G1 当作通过，也不得执行 rollback 中的 disable。

## 已保持有效的设计项

- ACME ownership、G0/G1/G2 的 ingress 分层、D3 的 pair/connect/heartbeat/tool-result 矩阵以及 G2 -> G1 gateway hard gate -> disable -> G0 的 rollback 顺序，未因本轮发现而被推翻。
- 它们都必须消费上述完整 provenance record；本轮 FAIL 不要求重新引入 gateway bypass、修改 Auth Mini、改变配置状态策略或改变 D3。
- D4 的真实浏览器登录仍是 G2 后的 production gate，不能替代 F1/F2，也不能在其前宣称完整上线验收。

## 会话注意力摘要

- 阶段：review-rfc
- 阶段结论：FAIL
- 注意力等级：review
- 判断变化：round 3 后新增的 final SHA、release manifest、Azar hash 复算和 G1 hash 对照缩小了 provenance 缺口；但 final source evidence 的比较/重跑分支，以及 active G1 executable 的 runtime binding 仍未被定义为可重算负路径。
- 关键发现：
  1. F1：final Git object 没有被机械绑定到可复用或 final-SHA 重跑的 C3 source evidence，故 G0 mutation 仍可绕过核心 state-preservation proof。
  2. F2：G1 仅核对 rendered `ExecStart`，没有核对 active process 的 canonical executable/hash，故 Azar binary 到 G1 的最后一跳不可验证。
  3. ACME、G0/G1/G2、D3 与 gateway-first rollback 的设计保持有效，但必须等待 F1/F2 的 provenance record 才能消费。
- 阻塞项：F1、F2。两者均为 D1 的 block-merge provenance gate；在修订 RFC 并重新通过独立 review-rfc 前，不得进入 engineer、merge 或 production rollout。
- 残余风险：D4 真实浏览器 Auth Mini redirect 登录仍须在 G2 后由 deployment operator 完成；其成功不能弥补 source/build/process provenance 缺口。
- 人类动作：复核 RFC 作者补入唯一 final-release-provenance record、final-vs-candidate compare-or-rerun 负路径，以及 active G1 process executable/hash 核验；停止点为修订版重新通过 review-rfc。
- 自动下一步：回到 spec-rfc，只补 F1/F2 的证据记录、机械核验和停止条件后重跑 review-rfc；保持 G0 gateway，不执行 `configure-auth`、G1 或 G2。
- 完整证据：
  - `.legion/tasks/constx-azar-native-auth-mini/docs/rfc.md:78-108`
  - `.legion/tasks/constx-azar-native-auth-mini/docs/rfc.md:110-149`
  - `.legion/tasks/constx-azar-native-auth-mini/docs/review-rfc-round3.md:16-45`
