# Review Change

## Decision

PASS.

## Blocking Findings

None.

## Scope Review

The repo diff is limited to `hosts/acorn/modules/auth-mini.nix` and adds an exact nginx root-path redirect for `auth.0xc1.wang`:

```nginx
location = / {
  return 302 /web/;
}
```

This is in scope for the hotfix because live diagnostics showed auth-mini serves the UI at `/web/` while `/` returns API `404`. The change does not alter gateway topology, protected vhosts, Vaultwarden, secrets, auth policy, or service users.

The live Cloudflare DNS change created the missing DNS-only A records for `auth.0xc1.wang` and `auth-gateway.0xc1.wang` to point at Acorn (`8.159.128.125`). This was required to address the reported empty response and matches the existing DNS-only shape used by `status-axiom.0xc1.wang` and `frps-acorn.0xc1.wang`.

## Correctness Review

- Nginx exact-match `location = /` has higher precedence than the catch-all `/` proxy location, so only the root path redirects.
- Non-root auth-mini paths continue to proxy to `127.0.0.1:7777` unchanged.
- Generated nginx config contains both the auth-mini proxy and exact-root redirect.
- Acorn toplevel build passed.
- Live evidence shows `auth-mini.service` is active and `GET /web/` returns valid HTML when requests reach Acorn.

## Security Review

Security lens applied because this task touches auth-facing routing and DNS.

No exploitable trust-boundary issue found:

- The redirect stays within the same origin and only moves `/` to `/web/`.
- The auth-mini service remains behind nginx on loopback `127.0.0.1:7777`.
- Gateway-protected host auth checks are unchanged.
- Vaultwarden remains outside the gateway and unchanged.
- No secrets were added, printed, or rotated.
- DNS records are DNS-only A records to the existing Acorn HTTPS endpoint, not Cloudflare-proxied Access records with a different auth boundary.

## Residual Risks

- The repo redirect is not live until this PR is merged and Acorn is switched again.
- Full auth-mini admin/bootstrap and gateway login flows are outside this hotfix's verification scope.
- Client environments using fake-ip DNS/proxy caches may need a browser/proxy DNS cache refresh after the Cloudflare records were created.
