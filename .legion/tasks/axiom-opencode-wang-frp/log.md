# Log

- Entered Legion workflow from the user request to add an FRP-backed OpenCode route with DNS and ACME.
- Clarified route ambiguity: selected a new parallel `opencode-axiom.0xc1.wang` route, not replacing the existing `opencode-axiom.0xc1.space` Cloudflared route.
- Wrote task contract, RFC, implementation plan, and RFC review. Design passed with Cloudflare Access edge auth plus nginx Basic Auth origin auth.
- Implemented Axiom frpc proxy `axiom-opencode-http` from `127.0.0.1:4096` to Acorn remote TCP `18081`.
- Implemented Acorn nginx vhost and DNS-01 ACME cert for `opencode-axiom.0xc1.wang`, proxying to `127.0.0.1:18081` with websockets and Basic Auth.
- Updated Legion wiki decisions with the new frp backend port and double-auth boundary.
- Cloudflare DNS update succeeded: `opencode-axiom.0xc1.wang` is a proxied `A` record to `8.159.128.125`.
- Cloudflare Access update succeeded: created/updated self-hosted app `opencode-axiom-wang` for `opencode-axiom.0xc1.wang` with Google-only IdP and exact-email allow policy for `c1@ntnl.io`, `siyuan.arc@gmail.com`, `froggy2818@gmail.com`, and `wangpeiguangwpg@gmail.com`.
- Targeted Nix assertions passed for the Axiom frpc proxy, Acorn nginx vhost, ACME provider, ACME host, and the Acorn firewall not opening TCP `18081`.
- `nix build` dry-runs and `--no-link` builds passed for both `axiom` and `aliyun-acorn`; `git diff --check` passed.
- Recorded `docs/test-report.md`, `docs/review-change.md`, `docs/report-walkthrough.md`, and `docs/pr-body.md`.
- Live deployment remains blocked on privileged host switching: Acorn needs remote sudo/root access, and final public/origin behavior checks must run after both hosts are switched.
