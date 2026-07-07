# Review Change

## Verdict

READY FOR PR.

No blocking code/config findings were found in the implemented change. Live deployment remains blocked by missing privileged access on `aliyun-acorn`, but that is an operational blocker rather than a code-readiness blocker.

## Scope Reviewed

- `hosts/axiom/default.nix`
- `hosts/aliyun-acorn/default.nix`
- `.legion/wiki/decisions.md`
- `.legion/tasks/axiom-opencode-wang-frp/**`
- Cloudflare DNS and Access state for `opencode-axiom.0xc1.wang`

## Findings

None blocking.

## Security Review

- Cloudflare DNS is proxied for `opencode-axiom.0xc1.wang`, which allows Cloudflare Access to protect normal public traffic.
- Cloudflare Access is a self-hosted app on exactly `opencode-axiom.0xc1.wang`, using the expected Google identity provider and exact email allowlist.
- Acorn nginx uses Basic Auth on the origin vhost, so direct origin access by IP plus Host/SNI does not bypass auth.
- Acorn nginx proxies only to `127.0.0.1:18081`, and targeted Nix eval confirms `18081` is not in `networking.firewall.allowedTCPPorts`.
- The existing `opencode-axiom.0xc1.space` Cloudflared route is unchanged.
- No plaintext frp token, Cloudflare token, or Basic Auth password was added to Git docs or Nix config.

## Residual Risks

- The origin Basic Auth file reuses the existing `nginx-status-htpasswd` secret. This is intentionally minimal for this task, but a future hardening task could split OpenCode origin credentials into a dedicated secret.
- Live route behavior is not proven until both Axiom and Acorn switch to the merged config and ACME issuance completes on Acorn.
- Cloudflare external state is live and verified now, but it is not yet declaratively managed in this repository.

## Required Deployment Follow-up

After PR merge and privileged host access:

```bash
nixos-rebuild switch --flake .#axiom
nixos-rebuild switch --flake .#aliyun-acorn --target-host c1@8.159.128.125 --use-remote-sudo --fast
```

Then verify Cloudflare Access challenge, origin Basic Auth `401`, and `18081` public inaccessibility.
