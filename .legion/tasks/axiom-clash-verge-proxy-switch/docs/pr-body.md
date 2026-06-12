## Summary

- Add `bin/clash-switch.ts`, a Node 24 TypeScript CLI for Clash Verge/Mihomo proxy group switching on axiom.
- Default to controller `http://127.0.0.1:9090` and group `Nexitally`, with flags/env overrides.
- Support `list`, `switch <node>`, shorthand node switching, and a no-argument TTY selector.

## Validation

- PASS: `node --version` -> `v24.13.0`
- PASS: `bin/clash-switch.ts --help`
- PASS: mock controller `list --json`
- PASS: mock controller `switch Japan`
- PASS: non-TTY interactive guard

## Notes

- No Clash config, Nix module, service, firewall, or subscription changes.
- Security lens applied for optional controller secret handling; no secrets are committed.
- `node --check` does not strip TypeScript declarations, so direct Node 24 execution and mock-controller runs are the validation evidence.
