# constx-azar-native-auth-mini 状态

- Profile: Strict
- 当前阶段: `release uplift blocked`（Azar sudo authentication；D3/D4 user deferred）
- Worktree: `.worktrees/constx-azar-native-auth-mini`
- Branch: `codex/constx-azar-native-auth-mini`

## Checklist

- [x] brainstorm：源代码/线上服务兼容性已收敛
- [x] spec-rfc：完成 config、ingress、build、rollback 设计
- [x] review-rfc round 1：FAIL（ACME ownership、TOML patch、active release、machine matrix 与 rollback gate）
- [x] review-rfc round 2：FAIL（target release 的 config state preservation release gate）
- [x] review-rfc round 3：FAIL（final merge 到 target binary 的可重算 provenance）
- [x] review-rfc round 4：FAIL（final source compare-or-rerun 与 active G1 executable binding）
- [x] review-rfc round 5：PASS（complete provenance record）
- [x] engineer：实现 specialisation、native config check 与 direct ingress
- [x] engineer：实施 source-aware Nix 变更
- [x] verify-change：Nix/build/runtime evidence（G1/G2 topology、source PR #83 release uplift、Azar binding）
- [x] review-change round 1：FAIL（runtime provenance records compressed to summaries）
- [x] review-change rerun：PASS（source/Axiom/Azar/G1/G2 provenance records）
- [x] delivery：PR #212 merged；Axiom build、Azar G2 rollout complete；D3/D4 user deferred
- [x] release uplift：Axiom build `059eab4`、Azar direct G2 switch、无敏感 runtime checks
- [x] release uplift：更新 release pin 到 PR #88 merge commit `a3cb397`
- [x] release uplift：Axiom build、Azar candidate release staging 与 Nix closure build
- [ ] release uplift：Azar G2 switch 与 runtime binary binding 验证（blocked：sudo authentication）
