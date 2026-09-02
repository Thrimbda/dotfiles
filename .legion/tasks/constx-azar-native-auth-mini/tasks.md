# constx-azar-native-auth-mini 状态

- Profile: Strict
- 当前阶段: `verify-change`
- Worktree: `.worktrees/constx-azar-native-auth-mini`
- Branch: `codex/constx-azar-native-auth-mini`

## Checklist

- [x] brainstorm：源代码/线上服务兼容性已收敛
- [ ] spec-rfc：完成 config、ingress、build、rollback 设计
- [x] review-rfc round 1：FAIL（ACME ownership、TOML patch、active release、machine matrix 与 rollback gate）
- [x] review-rfc round 2：FAIL（target release 的 config state preservation release gate）
- [x] review-rfc round 3：FAIL（final merge 到 target binary 的可重算 provenance）
- [x] review-rfc round 4：FAIL（final source compare-or-rerun 与 active G1 executable binding）
- [x] review-rfc round 5：PASS（complete provenance record）
- [x] engineer：实现 specialisation、native config check 与 direct ingress
- [ ] engineer：实施 source-aware Nix 变更
- [ ] verify-change：Nix/build/runtime evidence
- [ ] review-change：独立就绪度审查
- [ ] delivery：PR、merge、Axiom build、Azar rollout
