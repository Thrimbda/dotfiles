# RFC 审查（round 3）：Azar 上 Const X 原生 Auth Mini 部署

审查范围仅限当前部署任务的 plan.md、tasks.md、log.md、docs/research.md、docs/rfc.md，以及用户指定的 source candidate evidence：/Users/c1/Work/constx/.worktrees/constxd-auth-mini-native-sdk/.legion/tasks/constxd-auth-mini-native-sdk/docs/test-report.md 和其 docs/evidence/。本轮只审读已提交候选证据并交叉检查其可回溯的测试定位；未把候选分支、构建日志或 RFC 自述当作最终 release/生产事实，也未修改源代码。

## Verdict
FAIL

## 候选证据的独立判断

候选树 962ed79 包含 C3 的实质性 source evidence。test-report 记录 configure-auth 的 clean bootstrap、重复 enable/check/disable、disabled no-op、invalid/legacy 输入 no-write、非 auth 语义保全和 service-style XDG resolver；parallel retry 与 serial 的完整 cargo suite 均显示 148 passed、1 ignored，且列出的三个 configure-auth config tests 与 bootstrap process test 均通过。该证据足以关闭 round 2 所指出的“只有 atomic writer 名称、没有行为契约”的缺口。

但它只支持候选树。任务 log 仍把 962ed79 视为待合入 candidate；本地 origin/master 也未包含该 commit。source PR 的最终 merge 可能采用 squash、rebase、冲突解决或后续提交，故 candidate evidence 不能自动变成最终 release evidence。

## Findings

### F1：final merge SHA 被要求记录，但尚未形成可重算、fail-closed 的 release provenance gate

> [REVIEW:blocking] RFC 要求在部署时以最终 merge SHA 替换 962ed79，并要求 source merge SHA、binary SHA-256、Axiom build log 和 source test locator 相互对应；但没有规定如何在最终 source object 上验证这个对应关系。现有“最终 SHA 下 locator 仍可读”不能证明 C3 测试在该 SHA 上执行并通过，也不能证明被安装/用于 G0 的 binary 来自受到该测试覆盖的 source。缺少其中任一映射时，gate 仍可被人工填写的 SHA、未重跑的 candidate output 和独立 build log 表面满足，不能作为首次 config mutation 的 fail-closed 前置条件。
>
> [STATUS:open]

定位：docs/rfc.md:78-99 把 Config state preservation 放到任何 G0 mutation 前，并在 :82、:84、:93-99 使用 candidate SHA、final merge SHA、binary hash、build log 与 source locators；ordered rollout :111-116 则在 G0 先以目标 binary 写入 auth，再切 G1。candidate test-report :21-32 和 evidence/cargo-test-parallel-retry.txt、evidence/cargo-test-serial.txt 证明的是 candidate tree 的 C3 行为，而不是一个尚未知晓的 final merge object。

影响：G0 的 gateway 仍能防止公开 user API 窗口，却不能回滚一次错误 resolver 或错误 binary 对私有 runtime config 的写入。之后的 same-binary check 只证明 auth 值可被读取；它不能重建 provider、execution 或 database 语义，更不能证明 D3 所依赖的既有 provider 状态没有被破坏。因此，“没有证据不许 mutation”的意图正确，但当前缺少机械判定它是否取得证据的办法，状态保全验收和 rollback 可验证性仍不成立。

最小修复是在 RFC 内定义一个仅在 source 合入后执行的 final-release-provenance 子 gate，并将其结果作为 G0 的唯一入场券：

1. 由 source default branch 解析并固定 FINAL_MERGE_SHA；记录所检出的 Git object、最终 source tree 与候选 962ed79 的关系，PR head 不能替代 FINAL_MERGE_SHA。
2. 对 configure-auth 的实现、CLI、process/config tests、test-report 与 C3 raw evidence 定义精确比较范围。若这些 final blobs 与 candidate 对应 blobs 全部一致，可复用 candidate C3 evidence；任一 blob 不同、candidate 不是可比较基线或证据不可读时，必须在 FINAL_MERGE_SHA checkout 上重跑 C3 所需的 source tests，并保存新的无敏感 raw output、命令、exit status 和结果 locator。
3. 从同一 FINAL_MERGE_SHA 的 Axiom checkout 构建，记录 build input/derivation、target binary SHA-256 与最终 C3 evidence locator 的一一映射；G1 的 active ExecStart hash 和 G0 用于 configure-auth 的 executable 都必须匹配该 binary。
4. 明确负路径：FINAL_MERGE_SHA 未取得、比较不等、重跑失败、build/binary mapping 缺失或 Azar same-environment check 失败时，保持 G0 gateway，不得执行 configure-auth、G1 或 G2。

这不要求本部署任务改 Const X 源码，也不要求在 merge 前猜 final SHA；它要求把“final merge 时再核对”变成可重复的验证步骤和停止条件。修订后重跑 review-rfc 即可。

## G0/G1/G2、ACME、D3 与 rollback 复核

| 项目 | 本轮判定 | 理由 |
| --- | --- | --- |
| Config state preservation release gate | FAIL | candidate C3 行为证据充分，但缺 final merge object 到 C3 output、Axiom build 与实际 executable 的机械 provenance。 |
| G0 | BLOCKED | current gateway 继续提供外部 fail-closed 保护；但在 F1 通过前，Step 3 的首次 configure-auth 写入不得发生。 |
| G1 | 条件通过 | 目标 ExecStart、loopback 未认证 401、gateway active 与有效 auth_request 仍是明确硬门；它须消费 F1 产出的 final release record。 |
| G2 | 条件通过 | 仍仅可在全部 G1 gate 通过后进入，且要求 public/loopback 401、透明 vhost、无 gateway redirect/auth_request 与 ACME owner。 |
| ACME | 设计通过 | constx.0xc1.wang 的 owner 已明确迁移至 constx module，并要求在 G2 检查 rendered vhost/ACME owner；实际 Nix eval/activate 仍是后续验证，不能以本审查替代。 |
| D3 | 设计通过，运行时待验 | pair/connect/heartbeat/tool-result、机器凭据负例、用户 JWT 不可替代机器 token，以及 provider 条件不可取得即 INCONCLUSIVE/阻塞的矩阵保持完整。source suite 不能替代 G2 后的真实 canary。 |
| rollback | 条件通过 | G2 -> 同一 closure 的 G1 -> disable -> G0，以及 disable 前 gateway hard gate 仍防止 transparent/auth-disabled 组合；前提是 G1/G2 使用 F1 已绑定的最终 binary。 |

## 非阻塞事项

- candidate evidence 保留了一次与认证改动无关的并行 Pi runtime startup flake；同一 suite 的 retry 和 serial 均通过。它不推翻候选 C3，但 final-release-provenance 若需重跑 tests，应如实保留同类结果，不能只保留成功摘要。
- D4 的真实浏览器 Auth Mini redirect 登录仍是 G2 后的生产验收门；它不是 candidate C3 或本 RFC 审查的替代物。

除 F1 外，本轮没有发现新的设计 blocker。

## 会话注意力摘要

- 阶段：review-rfc
- 阶段结论：FAIL
- 注意力等级：review
- 判断变化：round 2 要求的 configure-auth 行为契约现有 962ed79 candidate 的测试和 raw evidence 已实质覆盖；本轮唯一剩余缺口不在 command 行为，而在尚未合入的 candidate 如何被绑定到 FINAL_MERGE_SHA、Axiom build 和 G0 实际 executable。
- 关键发现：
  1. F1（blocking）：最终 merge SHA 的文字要求没有比较/重跑、build-to-binary mapping 与失败停止条件，candidate C3 evidence 不能自动证明 final release。
  2. G1/G2、ACME、D3 四路径和 G2 -> G1 -> G0 rollback 的设计仍有效，但均不得绕过 F1。
  3. G0 gateway 可避免公开入口暴露，却不能证明一次错误 config mutation 可恢复。
- 阻塞项：F1。RFC 补入 final-release-provenance 子 gate 后，必须重新执行独立 review-rfc；在新的 PASS 前不得进入 engineer、merge 或 production rollout。
- 残余风险：D4 浏览器登录仍须由 deployment operator 在 G2 后完成；candidate 的 Pi startup flake 必须在最终 source test evidence 中如实处置。F1 未闭环时，不得以 gateway 存在宣称 runtime state 已安全。
- 人类动作：复核 RFC 作者将 FINAL_MERGE_SHA 比较或重跑规则、final build-to-binary mapping 和所有负路径写入 release gate；停止点为修订版 RFC 重新通过独立 review-rfc。
- 自动下一步：回到 spec-rfc，只补 F1 的 final-release-provenance 验证形状与映射后重跑 review-rfc；保持 G0，不进入 engineer、merge 或 production rollout。
- 完整证据：
  - .legion/tasks/constx-azar-native-auth-mini/log.md:7-9
  - .legion/tasks/constx-azar-native-auth-mini/docs/rfc.md:78-140
  - .legion/tasks/constx-azar-native-auth-mini/docs/review-rfc-round2.md:10-55
