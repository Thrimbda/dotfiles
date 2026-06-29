# RFC Review: Aliyun Acorn 0xc1.wang Entry

Decision: PASS

## Blocking Findings

None.

## Review Notes

- Scope is intentionally narrow and avoids migrating OpenCode before the Access boundary is redesigned.
- Rollback is clear because existing `0xc1.space` cloudflared routes stay untouched.
- Verification covers Nix evaluation, frp template shape, nginx auth wiring, and secret shape.
- Security boundary is explicit: direct `0xc1.wang` status access requires nginx Basic Auth and local-only frp backend port.

## Residual Risks

- DNS, ACME issuance, Aliyun security-group behavior, and live frp reachability require post-deploy checks.
- Basic Auth is weaker than Cloudflare Access but acceptable for this first protected status slice.
