# acorn-vaultwarden-package-update

## Metadata

- `task-id`: `acorn-vaultwarden-package-update`
- `status`: `completed`
- `risk`: `high`
- `schema-version`: `1.1`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- Acorn now runs Vaultwarden `1.37.0` and Web Vault `2026.6.4+0` from a dedicated `nixpkgs-vaultwarden` input; the primary Nixpkgs and shared unstable locks were unchanged.
- A pre-existing auth-mini fixed-output hash mismatch blocked the first required Axiom build. The package now uses the verified official GitHub release asset-ID API endpoint, content-negotiation header, and fixed SRI hash for `latest-2026-07-24`.
- A fresh Vaultwarden SQLite backup completed within the configured 15-minute deployment bound. The required Axiom build, closure transfer, remote activation, and status-only Vaultwarden/auth-mini health checks passed.
- Implementation PR [#154](https://github.com/Thrimbda/dotfiles/pull/154) was squash-merged as `dabc923b3826994f847c5eb1a809a365ff3519b3`; the user accepted the documented auth-mini provenance and deferred restore-drill risks. The implementation worktree was removed, and this closeout record precedes final closeout-worktree cleanup and main-workspace refresh.

## Reusable Decisions

- Keep Vaultwarden server and Web Vault assets on the same dedicated package input so a service-only update cannot retain an old Web Vault package.
- For mutable GitHub latest assets, pin an asset-ID API source plus request header and fixed-output hash; a later upstream change must fail the build rather than silently change an authentication binary.
- Acorn build safety remains absolute: build and deploy only from Axiom using the prescribed remote `nixos-rebuild switch` command, and stop on Axiom build, transfer, or activation failure.

## Related Raw Sources

- `plan`: `.legion/tasks/acorn-vaultwarden-package-update/plan.md`
- `log`: `.legion/tasks/acorn-vaultwarden-package-update/log.md`
- `tasks`: `.legion/tasks/acorn-vaultwarden-package-update/tasks.md`
- `rfc`: `.legion/tasks/acorn-vaultwarden-package-update/docs/rfc.md`
- `reviews`: `.legion/tasks/acorn-vaultwarden-package-update/docs/review-rfc.md`; `.legion/tasks/acorn-vaultwarden-package-update/docs/review-change.md`
- `report`: `.legion/tasks/acorn-vaultwarden-package-update/docs/report-walkthrough.md`
- `verification`: `.legion/tasks/acorn-vaultwarden-package-update/docs/test-report.md`

## Notes

- The current deployment and health evidence are task-local. Consult the raw verification and review documents for exact commands, timestamps, and residual-risk protocol.
