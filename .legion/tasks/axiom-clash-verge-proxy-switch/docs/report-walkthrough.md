# Report Walkthrough: Axiom Clash Verge Proxy Switch

Mode: implementation

## What Changed

- Added `bin/clash-switch.ts`, an executable Node 24 TypeScript CLI for switching the local Clash Verge/Mihomo proxy group.
- Defaults are tuned for axiom: controller `http://127.0.0.1:9090` and group `Nexitally`.
- Supported usage modes:
  - `clash-switch.ts list` to list group nodes.
  - `clash-switch.ts switch <node>` to switch to a named node.
  - `clash-switch.ts <node>` as shorthand for switching.
  - `clash-switch.ts` to open a terminal selector when attached to a TTY.
- Added runtime overrides for controller URL, group name, and optional API secret through flags and environment variables.

## Why

Axiom already has Clash Verge/Mihomo listening on `127.0.0.1:9090` and uses `Nexitally` as the selectable proxy group. The new CLI makes common node switching available from the terminal without modifying the Clash subscription, service configuration, or GUI workflow.

## Verification

Evidence: `docs/test-report.md`

- PASS: Node runtime is `v24.13.0`.
- PASS: executable `bin/clash-switch.ts --help` verifies the shebang/runtime path and documented modes.
- PASS: mock controller `list --json` verifies `GET /proxies` parsing and node list output.
- PASS: mock controller `switch Japan` verifies unique partial node resolution and `PUT /proxies/Nexitally` with `{ "name": "Japan 01" }`.
- PASS: non-TTY no-argument mode exits with an actionable error instead of waiting for input.
- Caveat: `node --check` does not strip TypeScript declarations and was not used as validation evidence; direct Node 24 execution with TypeScript stripping succeeded.

## Review

Evidence: `docs/review-change.md`

- PASS with no blocking findings.
- Scope is limited to a standalone `bin/` script plus task-local Legion evidence.
- No Clash YAML, Nix module, service, firewall, or subscription behavior was changed.
- Security lens applied for optional controller secret handling. No repository secrets, listeners, auth changes, or persistent credentials were introduced.

## Operational Notes

- Prefer `CLASH_API_SECRET` over `--secret` if the controller requires a secret, because command-line secrets can appear in shell history or process listings.
- Real axiom proxy switching was intentionally not performed during validation to avoid changing the user's live proxy selection.
