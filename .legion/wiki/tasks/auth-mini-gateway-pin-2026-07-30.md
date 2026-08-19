# Auth Mini Gateway Pin 2026-07-30

## Metadata

- `task-id`: `auth-mini-gateway-pin-2026-07-30`
- `status`: `completed`
- `risk`: `low`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

Goal was to align the declarative pin with the latest upstream gateway. Verification found `origin/master` already pins `Thrimbda/auth-mini-gateway@e1ea3e7` (`0.1.0-unstable-2026-07-30`, merged via PR #157), and an Axiom build of that pin produced store path `q62fpw730jv2c6hwh1swnysh5ih434bl`, byte-identical to the gateway running in Acorn's `/run/current-system` (both gateway units active). Declarative pin, Axiom build output, and Acorn runtime are three-way consistent; no PR or Acorn redeploy was needed.

## Reusable Decisions

- A pin-alignment task can be closed without a PR when store-path comparison proves `origin/master` pin, local build output, and deployed runtime already match.
- Acorn builds/deploys must always run from Axiom (`nixos-rebuild switch --build-host localhost`); never build on Acorn itself.

## Related Raw Sources

- `plan`: `.legion/tasks/auth-mini-gateway-pin-2026-07-30/plan.md`
- `log`: `.legion/tasks/auth-mini-gateway-pin-2026-07-30/log.md`
- `tasks`: `.legion/tasks/auth-mini-gateway-pin-2026-07-30/tasks.md`
