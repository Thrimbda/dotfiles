# Walkthrough: Aliyun Acorn 0xc1.wang Entry

Mode: implementation

## What Changed

- Added `axiom-gatus-http` to `axiom` frp client proxies, forwarding local Gatus `127.0.0.1:8080` to remote TCP `18080` on `aliyun-acorn`.
- Added `status-axiom.0xc1.wang` nginx vhost on `aliyun-acorn` with ACME, forced HTTPS, HTTP/2, websocket proxying, and Basic Auth.
- Added agenix rules and encrypted secret files for `nginx-status-htpasswd.age` and `status-basic-auth-password.age`.
- Left existing `0xc1.space` cloudflared routes unchanged.
- Did not expose `opencode-axiom.0xc1.wang`.

## Reviewer Focus

- `hosts/axiom/default.nix`: new frp proxy should remain TCP, local loopback, local Gatus port, remote `18080`.
- `hosts/aliyun-acorn/default.nix`: nginx vhost should require Basic Auth and proxy only to `127.0.0.1:18080`.
- `hosts/aliyun-acorn/default.nix`: firewall should not add `18080`.
- `hosts/aliyun-acorn/secrets/secrets.nix`: htpasswd secret should target `aliyun-acorn`; frp token handling remains unchanged.

## Validation Evidence

- `nix eval` toplevel derivation paths passed for `aliyun-acorn` and `axiom`.
- `nix build --dry-run` passed for both host toplevels.
- Secret format checks passed without printing secret contents.
- Evaluated `axiom` frp proxies include `axiom-gatus-http` remote `18080`.
- Generated `frpc.toml` contains the expected Gatus proxy and `frpc verify` passed.
- Generated `frps.toml` passed `frps verify`.
- Evaluated nginx location uses `basicAuthFile = /run/agenix/nginx-status-htpasswd` and `proxyPass = http://127.0.0.1:18080`.
- Evaluated firewall ports are `[22,80,443,2222,2225,7000,34197]`; `18080` is absent.

Evidence source: `docs/test-report.md`.

## Review Evidence

Change review passed with the security lens applied to auth, secrets, and public ingress boundaries.

Evidence source: `docs/review-change.md`.

## Post-deploy Checks

- Create Cloudflare DNS records for `status-axiom.0xc1.wang` and `axiom.0xc1.wang`, DNS-only, pointing to `8.159.128.125`.
- Deploy `axiom` and `aliyun-acorn` configs.
- Confirm ACME issuance and HTTPS Basic Auth behavior for `status-axiom.0xc1.wang`.
- Confirm `127.0.0.1:18080` responds on `aliyun-acorn` after frp connects.
- Confirm external access to `18080` is blocked.
- Confirm `ssh -p 2225 c1@axiom.0xc1.wang` reaches Axiom.
