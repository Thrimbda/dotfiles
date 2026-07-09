# Test Report

## Summary

PASS with one deploy-pending repo fix.

Live diagnostics show `auth-mini.service` is healthy on Acorn and the auth-mini UI responds at `/web/` when requests reach `8.159.128.125`. The browser empty response was caused by missing Cloudflare DNS records for `auth.0xc1.wang` and `auth-gateway.0xc1.wang`, which made local/proxy DNS resolve to `198.18.x.x` fake-ip addresses instead of Acorn. Those DNS records were created live as DNS-only A records to `8.159.128.125`.

The repo fix adds an nginx exact-root redirect so `https://auth.0xc1.wang/` redirects to `/web/` after the next Acorn switch. Without this, the root path reaches auth-mini's API fallback and returns JSON `404`, while the web UI lives at `/web/`.

## Commands And Evidence

### Live Acorn Service Diagnostics

Command:

```sh
ssh -o BatchMode=yes -o ConnectTimeout=10 c1@8.159.128.125 'set -eu; hostname; systemctl is-active auth-mini.service || true; systemctl --no-pager --full status auth-mini.service || true; journalctl -u auth-mini.service -n 80 --no-pager; journalctl -u nginx.service -n 80 --no-pager; curl -i --max-time 5 http://127.0.0.1:7777/ || true; curl -i --max-time 5 http://127.0.0.1:7777/web/ || true'
```

Result:

- Host: `aliyun-acorn`.
- `auth-mini.service` status: `active (running)`.
- auth-mini log: `auth-mini rust backend listening on 127.0.0.1:7777`.
- Loopback `GET /`: `HTTP/1.1 404 Not Found` with `{"error":"not_found"}`.
- Loopback `GET /web/`: `HTTP/1.1 200 OK` with auth-mini HTML.
- Nginx logs showed only proxy header hash warnings and successful reloads; no upstream crash evidence.

### Direct Acorn HTTPS Smoke

Command:

```sh
curl -vk --resolve auth.0xc1.wang:443:8.159.128.125 --max-time 15 https://auth.0xc1.wang/web/ || true
curl -vk --resolve auth.0xc1.wang:443:8.159.128.125 --max-time 15 https://auth.0xc1.wang/ || true
```

Result:

- `GET /web/`: `HTTP/2 200`, valid `auth-mini demo` HTML.
- `GET /`: `HTTP/2 404`, `{"error":"not_found"}` before this hotfix is deployed.
- Certificate presented: CN `auth.0xc1.wang`, Let's Encrypt, valid from `2026-07-09` to `2026-10-07`.

### DNS Root Cause And Live DNS Fix

Initial local test:

```sh
curl -vkI --max-time 15 https://auth.0xc1.wang/ || true
```

Result:

- Local resolver returned `198.18.0.60`, not `8.159.128.125`.
- TLS failed with unexpected EOF, matching the browser's empty response behavior.

Cloudflare record query before creation showed no A records for `auth.0xc1.wang` or `auth-gateway.0xc1.wang`.

Live DNS records created using the existing Cloudflare DNS token:

- `auth.0xc1.wang` A `8.159.128.125`, `proxied=false`, `ttl=1`.
- `auth-gateway.0xc1.wang` A `8.159.128.125`, `proxied=false`, `ttl=1`.

Verification command:

```sh
curl -fsS -H 'accept: application/dns-json' 'https://cloudflare-dns.com/dns-query?name=auth.0xc1.wang&type=A'
curl -fsS -H 'accept: application/dns-json' 'https://cloudflare-dns.com/dns-query?name=auth-gateway.0xc1.wang&type=A'
```

Result:

- Cloudflare DoH returns `auth.0xc1.wang A 8.159.128.125`.
- Cloudflare DoH returns `auth-gateway.0xc1.wang A 8.159.128.125`.

Note: Acorn cannot reach `1.1.1.1:53` directly from this environment (`dig @1.1.1.1` timed out), so Cloudflare API/DoH is the authoritative verification for the DNS control-plane change.

### Repo Build And Generated Config

Command:

```sh
nix build --impure --no-link .#nixosConfigurations.acorn.config.system.build.toplevel
```

Result: PASS.

Generated nginx config evidence:

```nginx
server_name auth.0xc1.wang ;
location / {
  proxy_pass http://127.0.0.1:7777;
  proxy_http_version 1.1;
  proxy_set_header Upgrade $http_upgrade;
  proxy_set_header Connection $connection_upgrade;
}
location = / {
  return 302 /web/;
}
```

Nix eval evidence:

```sh
nix eval --impure --json --expr '(builtins.getFlake (toString ./.)).nixosConfigurations.acorn.config.services.nginx.virtualHosts."auth.0xc1.wang".locations."= /"'
```

Result includes:

```json
{"extraConfig":"return 302 /web/;\n"}
```

### Whitespace

Command:

```sh
git diff --check
```

Result: PASS.

## Skipped Or Pending

- The root-path `302 /web/` behavior is verified in generated config but not yet live, because it requires this repo fix to be merged and switched on Acorn.
- Full auth/admin bootstrap and protected-site login flow were not retested; this hotfix targets the empty response / root UX issue only.

## Post-Deploy Smoke

After this PR is switched on Acorn, run:

```sh
curl -I https://auth.0xc1.wang/
curl -fsS https://auth.0xc1.wang/web/ >/dev/null
```

Expected:

- Root returns `302` with `Location: /web/`.
- `/web/` returns success HTML.
