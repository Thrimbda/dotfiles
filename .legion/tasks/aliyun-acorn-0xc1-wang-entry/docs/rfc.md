# RFC: Aliyun Acorn 0xc1.wang Entry

## Decision

Implement the first `0xc1.wang` slice as an nginx-protected Gatus status endpoint on `aliyun-acorn`, with the backend carried over the existing frp tunnel from `axiom`.

## Route Shape

- DNS: `status-axiom.0xc1.wang` A record to `8.159.128.125`, DNS-only.
- Edge: nginx on `aliyun-acorn`, `forceSSL = true`, `enableACME = true`, Basic Auth enabled.
- Backend: nginx proxies to `http://127.0.0.1:18080`.
- Tunnel: `axiom` frpc exposes local `127.0.0.1:8080` as remote TCP `18080` on `aliyun-acorn`.

## Exclusions

- `opencode-axiom.0xc1.wang` is not exposed in this task.
- Existing `0xc1.space` cloudflared routes are not changed.
- Cloudflare DNS automation is not added to dotfiles.

## Alternatives Considered

- Expose OpenCode at the same time: rejected because OpenCode currently relies on Cloudflare Access and should not be moved to direct nginx without a separate Access design.
- Use Cloudflare-proxied `0xc1.wang` with Access now: rejected for this slice because the user asked for aliyun-acorn as server and the plan keeps DNS-only direct nginx first.
- Make `status-axiom.0xc1.wang` public: rejected because status content can reveal service inventory and health state.

## Security

- Store Basic Auth material in agenix secrets.
- Configure the htpasswd age secret with nginx-readable ownership.
- Keep frp backend `18080` local-only and out of firewall/security-group public surfaces.
- Preserve existing Cloudflare Access for `status-axiom.0xc1.space` as fallback.

## Rollback

- Remove the `status-axiom.0xc1.wang` DNS record or point it away from `aliyun-acorn`.
- Roll back `aliyun-acorn` nginx vhost and `axiom` frp proxy changes with NixOS generations.
- Keep using `status-axiom.0xc1.space` through cloudflared.
- Rotate Basic Auth and frp credentials if exposed.

## Verification Plan

- Evaluate and dry-run build `aliyun-acorn` and `axiom`.
- Confirm evaluated `axiom` frp proxies include `axiom-gatus-http` remote `18080`.
- Confirm evaluated `aliyun-acorn` firewall ports do not include `18080`.
- Build/inspect frpc template and run `frpc verify`; run `frps verify` for server template.
- Confirm nginx vhost evaluates with `basicAuthFile` from `config.age.secrets.nginx-status-htpasswd.path`.
- Validate both Basic Auth age secrets decrypt with the expected non-printing shape checks.
