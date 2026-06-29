# Log: Aliyun Acorn 0xc1.wang Entry

## 2026-06-29

- User approved the plan in `.opencode/plans/1781936355557-kind-star.md`.
- Scope is narrowed to `status-axiom.0xc1.wang` plus `axiom.0xc1.wang` DNS convenience; all `0xc1.space` cloudflared routes remain unchanged.
- OpenCode is explicitly deferred because direct nginx exposure would remove the existing Cloudflare Access boundary.
- Basic Auth credentials will be generated for username `c1`; both htpasswd and plaintext password retrieval material will be encrypted with agenix and not printed in final output.
- Implemented the planned `axiom-gatus-http` frp proxy and `status-axiom.0xc1.wang` nginx vhost with `basicAuthFile` wired to an agenix secret.
- Verification passed for host eval, dry-run builds, frp templates, nginx auth/TLS fields, htpasswd secret ownership, firewall ports, and encrypted secret formats. Live DNS/ACME/frp reachability remain post-deploy checks.
- Change review passed with security lens applied to Basic Auth, secrets, and public ingress boundaries.
- Generated implementation walkthrough and PR body from the existing verification/review evidence.
- Wrote Legion wiki task summary and updated current FRP/status-page decisions for the `0xc1.wang` first slice.
