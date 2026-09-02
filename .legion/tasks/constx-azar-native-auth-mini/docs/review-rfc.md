# RFC 窄范围审查：final source evidence 与 G1 binary provenance

审查范围严格限于 `docs/rfc.md` 的：

- `Final source evidence compare-or-rerun`；
- `Final merge to target-binary provenance`；
- G1 table 与 `Ordered rollout` 对上述两项的消费。

未审查实现、Nix 配置、部署产物、其他 rollout gate 或生产运行状态。

## Verdict

PASS

## 审查结论

### 1. final SHA 与候选 C3 evidence 的 compare-or-final-rerun

通过。RFC 将 final source object 固定为 `92112facdb30a1a3a02e0a31fadcf3ff4a6ea379`，并要求 Axiom 生成 `source-evidence-compare.txt`，逐项记录 baseline/final blob id 与 `git diff --quiet` 结果。复用 merged C3 evidence 只有在以下条件同时满足时才允许：baseline object 可读、所有 final blob 与表中值一致、指定 paths 的 diff 为零、且完整 checkout 从 baseline 至 final 的 diff 也为零。

任一 candidate ref/object 不可读、blob/diff 不一致，或 compare 输出不能保存，均强制在 final clean checkout 重跑列出的 C3 命令集，并将脱敏 raw output、exit status 与 final SHA 写入 `source-evidence-rerun.txt`；任一命令失败即停止于 G0。该分支是机械、fail-closed 的，未留下“比较失败但继续复用候选证据”的路径。

该结果被后续门禁实际消费：release manifest 绑定 `source_merge_sha`、`source_evidence_mode` 与 `source_evidence_record`；G1 table 明列 `source evidence compare/rerun PASS`，ordered rollout 第 1 步也要求在构建 release binary 前完成 compare 或 final rerun。

### 2. G1 effective ExecStart、MainPID canonical executable 与 SHA binding manifest

通过。RFC 要求 release manifest 同时记录 `binary_sha256`、`azar_release_binary` 与 `azar_release_binary_canonical`。G1 activate 后必须生成 `g1-executable-binding.txt`，记录 effective systemd `ExecStart` 的 executable path、`MainPID`、`readlink -f /proc/$MainPID/exe` 与该 executable 的 SHA-256。

门禁要求 unit path、PID canonical executable、manifest canonical path，以及两侧 SHA-256 全部相等；任一 resolver、PID、path、hash 或 unit-state 不可读或不一致，均保持或回到 G0 gateway，禁止进入 G2。这不是仅检查 unit 文本或 release 文件存在，而是对实际 MainPID 所执行的 canonical executable 做 SHA 绑定。

该绑定同样被消费：G1 table 要求 active `ExecStart` path、`MainPID` executable canonical path、SHA-256 全部匹配 release manifest；ordered rollout 第 4 步要求生成并通过该 record 和 G1 table 的全部 gate，失败不得进入 G2。

## Blocking findings

无。

## 非阻塞说明

无。本审查仅确认 RFC 的设计门禁；实际 rollout 时仍须按 RFC 生成并保存指定 record，不能以本文结论替代运行时证据。

## 会话注意力摘要

- 阶段：review-rfc
- 阶段结论：PASS
- 注意力等级：none
- 判断变化：无。
- 关键发现：
  1. compare-or-rerun 的全部失败路径均停止复用并在 rerun 失败时停在 G0。
  2. G1 将 effective `ExecStart`、实际 `MainPID` 的 canonical executable 与 manifest SHA 作全等绑定，并禁止不一致时进入 G2。
- 阻塞项：无。
- 残余风险：无（限本次 RFC 审查范围）。
- 人类动作：无动作。
- 自动下一步：交回既定 rollout；在 G0/G1 执行时按 RFC 生成并验证对应 release manifest、`source-evidence-compare.txt` 或 `source-evidence-rerun.txt`、以及 `g1-executable-binding.txt`。
- 完整证据：`docs/rfc.md:93-116`、`docs/rfc.md:125-141`。
