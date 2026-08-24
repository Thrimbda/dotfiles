# decommission-oneex-portfolio-account

## Metadata

- `task-id`: `decommission-oneex-portfolio-account`
- `status`: `completed`
- `risk`: `medium`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `deploy-oneex-portfolio-acorn` (active Acorn deployment)
- `superseded-by`: `(none)`

## Outcome Summary

- PR [#203](https://github.com/Thrimbda/dotfiles/pull/203) merged as `df26dce7f6b0652172cf5d604527f18d73cd76a5`; its complete production change removed only `./modules/oneex-portfolio-adapter.nix` from `hosts/acorn/default.nix`.
- The mandated Axiom-to-Acorn switch deployed generation `/nix/store/aasj72hy0vdl7sbgdgfib54x4bnhgggc-nixos-system-acorn-26.05.7813.0dd31db7e6db`, whose configuration revision is the merged commit. No Nix evaluation or build ran on Acorn.
- Final runtime proof found the adapter and ACME units absent, no adapter process or TCP `8090` listener, and no adapter hostname or port in active nginx. Verified TLS rejected the hostname; the unauthenticated diagnostic reached only the default `404`. All nine checked unrelated services remained active and no failed unit existed.
- The runtime age secret, ciphertext/declaration, dormant adapter module, and package snapshot remain intentionally. External 1Exchange/auth-mini metadata and credentials also remain; no external account, browser, authentication, credential, or secret mutation occurred.

## Reusable Decisions

- Removing a host's sole import of a service module retires the service, vhost/ACME contribution, and module-owned package evaluation without deleting dormant source artifacts.
- Verify retirement and retained secrets separately: evaluate service/vhost absence and age-secret presence, then prove runtime unit/process/listener/vhost absence without reading secret content.

## Related Raw Sources

- `plan`: `.legion/tasks/decommission-oneex-portfolio-account/plan.md`
- `log`: `.legion/tasks/decommission-oneex-portfolio-account/log.md`
- `tasks`: `.legion/tasks/decommission-oneex-portfolio-account/tasks.md`
- `rfc`: `.legion/tasks/decommission-oneex-portfolio-account/docs/rfc.md`
- `reviews`: `.legion/tasks/decommission-oneex-portfolio-account/docs/review-rfc.md`, `.legion/tasks/decommission-oneex-portfolio-account/docs/review-change.md`
- `test report`: `.legion/tasks/decommission-oneex-portfolio-account/docs/test-report.md`
- `report`: `.legion/tasks/decommission-oneex-portfolio-account/docs/report-walkthrough.md`
