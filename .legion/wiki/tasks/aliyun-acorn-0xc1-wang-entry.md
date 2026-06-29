# Aliyun Acorn 0xc1.wang Entry

Status: ready for PR

## Summary

Adds the first `0xc1.wang` public entry slice on `aliyun-acorn`: `status-axiom.0xc1.wang` terminates HTTPS in nginx, enforces Basic Auth, and proxies to Axiom Gatus through frp remote TCP `18080`.

Existing `0xc1.space` cloudflared routes remain unchanged. `opencode-axiom.0xc1.wang` is explicitly deferred until a separate Cloudflare Access design exists.

## Current Shape

- `axiom` frpc keeps `axiom-ssh`: `127.0.0.1:22 -> 2225`.
- `axiom` frpc adds `axiom-gatus-http`: `127.0.0.1:8080 -> 18080`.
- `aliyun-acorn` nginx serves `status-axiom.0xc1.wang` with ACME, forced HTTPS, HTTP/2, websocket proxying, and Basic Auth.
- nginx proxies status traffic to `http://127.0.0.1:18080`.
- `18080` is not opened in the NixOS firewall.
- Basic Auth material is stored as encrypted age files under `hosts/aliyun-acorn/secrets/`.

## Verification

- `nix eval` toplevel derivation paths passed for `aliyun-acorn` and `axiom`.
- `nix build --dry-run` passed for both host toplevels.
- `frpc verify` and `frps verify` passed against generated templates.
- Evaluated nginx location uses `/run/agenix/nginx-status-htpasswd` and `http://127.0.0.1:18080`.
- Evaluated firewall ports exclude `18080`.
- Secret shape checks passed without printing secret contents.

## Operational Follow-up

- Create DNS-only Cloudflare records: `status-axiom.0xc1.wang -> 8.159.128.125`, `axiom.0xc1.wang -> 8.159.128.125`.
- Deploy both host configs.
- Verify ACME issuance, public Basic Auth behavior, live frp backend reachability, external `18080` blocking, and SSH via `ssh -p 2225 c1@axiom.0xc1.wang`.

## Source Evidence

- Raw task: `.legion/tasks/aliyun-acorn-0xc1-wang-entry/`
- RFC: `.legion/tasks/aliyun-acorn-0xc1-wang-entry/docs/rfc.md`
- Test report: `.legion/tasks/aliyun-acorn-0xc1-wang-entry/docs/test-report.md`
- Change review: `.legion/tasks/aliyun-acorn-0xc1-wang-entry/docs/review-change.md`
