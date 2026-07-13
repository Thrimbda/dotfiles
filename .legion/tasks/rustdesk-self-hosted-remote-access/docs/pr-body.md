## Summary

- Fix Axiom RustDesk connectivity through Clash by resolving `rustdesk.0xc1.wang` directly to Acorn.
- Give the spawned server the current c1 Hyprland/DBus coordinates while keeping root configuration under `/root`.
- Expose PipeWire's GStreamer plugin through an immutable Nix path.
- Produce a fresh legal composite revision so the invalid deployed ready state can only move forward.

## Scope

Production changes are limited to `hosts/axiom/default.nix`. Acorn, Charlie, secrets, modules and the provision/finalizer state machine are unchanged.

## Validation

- Round 9 RFC review: PASS.
- Exact resolver/environment/revision checks: PASS.
- `pipewiresrc`, `videoconvert`, `appsink`: PASS.
- Stale-state and old-finalizer negative tests: PASS.
- Generated scripts and ShellCheck: PASS.
- Full Axiom build: `/nix/store/lx4xz9nwrsaxkayb9byp1fk1p1s5mybf-nixos-system-axiom-25.11.20260630.b6018f8`.
- Change review: PASS, no blocking findings.

Candidate runtime is intentionally pending. After merge, Axiom must complete fresh state, live environment, screen/input, password positive/negative and manual-finalize gates before Charlie is deployed. Any failure after reservation requires RustDesk stopped plus another fixed-forward revision, never generation rollback.

Walkthrough: [`.legion/tasks/rustdesk-self-hosted-remote-access/docs/report-walkthrough.md`](.legion/tasks/rustdesk-self-hosted-remote-access/docs/report-walkthrough.md)
