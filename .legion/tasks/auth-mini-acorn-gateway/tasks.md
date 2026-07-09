# Tasks

- [x] Materialize task contract | Acceptance: `plan.md` describes goal, scope, non-goals, assumptions, risks, acceptance, and phases.
- [x] Produce RFC | Acceptance: `docs/rfc.md` covers package/source strategy, service topology, nginx auth_request flow, secrets, rollback, and verification.
- [x] Review RFC | Acceptance: `docs/review-rfc.md` records PASS or required changes before implementation.
- [x] Implement Acorn auth services | Acceptance: `auth-mini` and `auth-mini-gateway` packages/services/secrets/vhosts are declared in Nix.
- [x] Migrate protected vhosts to gateway | Acceptance: status, opencode, and frps dashboard vhosts use gateway `auth_request`; Vaultwarden remains unchanged.
- [x] Verify change | Acceptance: `docs/test-report.md` records successful eval/build and generated config checks or exact blockers.
- [x] Review implementation | Acceptance: `docs/review-change.md` records readiness decision and any residual risk.
- [x] Produce reviewer walkthrough | Acceptance: `docs/report-walkthrough.md` and `docs/pr-body.md` summarize the change and evidence.
- [x] Write wiki summary | Acceptance: `.legion/wiki` records reusable decisions and task outcome.
- [ ] Complete PR lifecycle | Acceptance: branch is pushed, PR is opened/updated, checks/review are followed to terminal state, worktree cleanup and main refresh are handled or blockers are logged.
