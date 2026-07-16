## Summary

- Move status and OpenCode authentication enforcement to minimal, host-local Axiom gateway services while retaining auth-mini, TLS termination, and FRP ingress on Acorn.
- Route FRP through Axiom loopback gateways, preserve Acorn proxy behavior for cookies, WebSockets, uploads, and streaming, and keep internal ports off host firewalls.
- Pin `auth-mini-gateway` to `28a4a273ea9b2725191dce35233f55972beaac6f` and add an Axiom-only encrypted environment secret with hardened, separate service state.

## Validation

- PASS: pinned gateway package build.
- PASS: Axiom toplevel build without activation.
- PASS: targeted Acorn/Axiom service, FRP, nginx, firewall, secret-metadata, and hardening assertions.
- PASS: `git diff --check` and scoped readiness review; no blocking findings.

## Rollout notes

- **No live deployment was performed.** No Acorn closure build, switch, activation, or runtime cutover test was run.
- Existing status/OpenCode gateway sessions will reset at cutover because the Axiom gateways use fresh databases and a new cookie secret.
- With `TRUSTED_PROXY_CIDRS` empty, applications see the loopback FRP peer rather than the original client IP.

**Mode:** `implementation`
