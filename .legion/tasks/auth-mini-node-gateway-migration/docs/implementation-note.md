# Simplified Implementation

The initial design added a reusable module, generated nginx fixture, custom contract test, and privileged secret scanner. The user rejected that complexity. This note supersedes the RFC as the implementation source of truth.

## Change

- Pin `auth-mini-gateway` to `28a4a273ea9b2725191dce35233f55972beaac6f`.
- Keep Acorn's existing auth-mini and gateway service generation. Remove only the local `status-axiom` and `opencode-axiom` gateway instances.
- Add direct Acorn nginx vhosts for status and OpenCode that preserve cookies and streaming while proxying to FRP ports `18080` and `18081`.
- Define two Axiom-local gateway services on `127.0.0.1:7779` and `127.0.0.1:7780`, proxying to Gatus `8080` and OpenCode `4096`.
- Point the existing FRP proxies at the two gateway ports.
- Add one Axiom-only encrypted environment file containing the existing allowlist policy and a new cookie secret.

## Validation

- Build the pinned gateway package.
- Build the Axiom toplevel without activation.
- Evaluate the exact Acorn/Axiom service, FRP, nginx, firewall, and secret metadata needed by this change.
- Run `git diff --check` and a scoped review.

No live deployment or Acorn closure build is part of this PR.
