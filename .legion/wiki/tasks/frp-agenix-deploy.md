# FRP Agenix Deploy

## Metadata

- `task-id`: `frp-agenix-deploy`
- `status`: `active`
- `risk`: `medium`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

This task adds a declarative frp path alongside the existing autossh reverse SSH path. `aliyun-acorn` runs `frps` on TCP `7000`, and `axiom` runs `frpc` against `8.159.128.125:7000` to expose local SSH through remote TCP `2225`.

The shared frp token is generated as a strong random value and stored only as host-local agenix secrets. Runtime TOML is rendered from `/run/agenix/frp-token` into `/run/frps` or `/run/frpc`, so Nix store templates contain only `@FRP_TOKEN@`.

The repository now marks `*.age` as binary in `.gitattributes` so encrypted payloads are not parsed by Git whitespace checks.

During writeback, existing `azar` autossh ownership of remote loopback `2224` was discovered and the frp proxy was moved to `2225` to avoid a port conflict.

## Reusable Decisions

- Keep frp token auth secrets host-local and render TOML at service start; do not interpolate token strings into Nix-generated store files.
- Reserve frp `axiom-ssh` remote TCP `2225` on `8.159.128.125`; do not reuse autossh `2222`, `2223`, or `2224` reservations for public frp proxies.
- Keep the existing autossh reverse SSH path in place; frp is an additional path until a future scoped task explicitly changes migration policy.

## Validation

Validation passed for host-local secret consistency, `axiom` and `aliyun-acorn` toplevel evals, dry-run builds, generated service ordering, frp render-script inspection, `frpc verify`, `frps verify`, final `2225` port configuration, and `git diff --check`.

## Related Raw Sources

- `plan`: `.legion/tasks/frp-agenix-deploy/plan.md`
- `log`: `.legion/tasks/frp-agenix-deploy/log.md`
- `tasks`: `.legion/tasks/frp-agenix-deploy/tasks.md`
- `rfc`: `.legion/tasks/frp-agenix-deploy/docs/rfc.md`
- `review-rfc`: `.legion/tasks/frp-agenix-deploy/docs/review-rfc.md`
- `test-report`: `.legion/tasks/frp-agenix-deploy/docs/test-report.md`
- `review`: `.legion/tasks/frp-agenix-deploy/docs/review-change.md`
- `walkthrough`: `.legion/tasks/frp-agenix-deploy/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/frp-agenix-deploy/docs/pr-body.md`

## Notes

- Runtime deployment still needs host rebuild/switch and live service health checks.
- The HTML walkthrough render handoff is artifact-only/blocker because this repo does not currently have a Pages PR preview workflow.
