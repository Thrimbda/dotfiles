# Report Walkthrough: Axiom Cloudflared HTTP2 Transport Fix

Mode: implementation.

## What Changed

- Added `protocol = "http2"` to axiom's cloudflared `extraConfig` in `hosts/axiom/default.nix`.
- Left tunnel id, credential path, hostname, ingress origin, opencode service, Cloudflare Access policy, and Clash/DNS settings unchanged.
- Added Legion task evidence under `.legion/tasks/axiom-cloudflared-http2-transport/**`.

## Why

Runtime inspection showed opencode itself was healthy on `127.0.0.1:4096` and cloudflared ingress still targeted that origin. The failing leg was cloudflared's default QUIC transport to Cloudflare edge through the current Clash/Meta fake-ip path, where edge hosts resolve to `198.18.0.x` and QUIC repeatedly times out.

Manual HTTP/2 connector testing registered successfully with Cloudflare edge and restored the public hostname to a Cloudflare Access redirect, so the durable fix is to set the declarative connector protocol to HTTP/2.

## Evidence

- Design-lite: `.legion/tasks/axiom-cloudflared-http2-transport/docs/rfc.md`
- Verification: `.legion/tasks/axiom-cloudflared-http2-transport/docs/test-report.md`
- Review: `.legion/tasks/axiom-cloudflared-http2-transport/docs/review-change.md`

## Verification Summary

- PASS: generated `/etc/cloudflared/config.yml` contains `"protocol":"http2"` while preserving current ingress/tunnel values.
- PASS: cloudflared systemd `ExecStart` still uses `--config /etc/cloudflared/config.yml`.
- PASS: `nix build .#nixosConfigurations.axiom.config.system.build.toplevel --dry-run` evaluates and plans the axiom toplevel build.
- Non-blocking: `nix flake check --no-build` fails on an existing `mkApp` path/string issue unrelated to this host-level change.

## Review Summary

`review-change` verdict: PASS.

Security lens was applied because this changes a transport/protocol boundary. No credentials, Access policy, listener exposure, hostname, route, or origin service changed.

## Operational Follow-up

- Deploy the dotfiles change to axiom and restart `cloudflared.service`.
- Confirm system logs show registered `protocol=http2` connections.
- Confirm `https://opencode-axiom.0xc1.space` still reaches Cloudflare Access.
- Stop the temporary user-level HTTP/2 connector after the system service is healthy.
