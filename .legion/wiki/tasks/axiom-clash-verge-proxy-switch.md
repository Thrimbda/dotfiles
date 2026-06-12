# Axiom Clash Verge Proxy Switch

## Metadata

- `task-id`: `axiom-clash-verge-proxy-switch`
- `status`: `active`
- `risk`: `low`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

Axiom now has a standalone Node 24 TypeScript CLI at `bin/clash-switch.ts` for local Clash Verge/Mihomo proxy group control. The script defaults to controller `http://127.0.0.1:9090` and proxy group `Nexitally`, matching the existing axiom Clash config and the confirmed task contract.

The CLI supports listing group nodes, switching by explicit command-line node argument, shorthand node switching, and a no-argument terminal selector when run from a TTY. Controller URL, proxy group, and optional API secret remain runtime-configurable through flags and environment variables.

## Reusable Decisions

- For axiom Clash Verge node switching, use the local Clash/Mihomo controller API rather than editing subscription YAML or proxy-group definitions.
- Keep controller secrets out of repository files. Prefer `CLASH_API_SECRET` over `--secret` when a controller secret is needed, because command-line secrets can appear in shell history or process listings.
- Do not validate local controller switch tools by changing the live workstation proxy unless the task explicitly scopes a live switch smoke test; use a mock controller for deterministic API behavior.

## Validation

Local validation passed on Node `v24.13.0` for executable help output, mock `GET /proxies` list behavior, mock `PUT /proxies/Nexitally` switch behavior, unique partial node matching, and non-TTY interactive guard behavior.

`node --check` was not used as validation evidence because it did not strip TypeScript declarations before syntax checking. Direct Node 24 execution with TypeScript stripping and mock-controller behavior are the accepted evidence for this dependency-free `.ts` script.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-clash-verge-proxy-switch/plan.md`
- `log`: `.legion/tasks/axiom-clash-verge-proxy-switch/log.md`
- `tasks`: `.legion/tasks/axiom-clash-verge-proxy-switch/tasks.md`
- `test-report`: `.legion/tasks/axiom-clash-verge-proxy-switch/docs/test-report.md`
- `review`: `.legion/tasks/axiom-clash-verge-proxy-switch/docs/review-change.md`
- `walkthrough`: `.legion/tasks/axiom-clash-verge-proxy-switch/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/axiom-clash-verge-proxy-switch/docs/pr-body.md`

## Notes

- The real axiom proxy selection was not changed during validation.
- The script does not modify Clash config, Nix modules, services, firewall policy, or subscriptions.
