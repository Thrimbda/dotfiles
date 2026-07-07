# Review Change

## Verdict

READY FOR PR.

No blocking correctness, scope, or security findings were found. Live deployment remains blocked by Acorn privileged activation access, but the code/config change is ready.

## Scope Reviewed

- `hosts/acorn/default.nix`
- `.legion/wiki/decisions.md`
- `.legion/tasks/acorn-frps-dashboard-nginx/**`
- Cloudflare DNS state for `frps-acorn.0xc1.wang`

## Findings

None blocking.

## Security Review

- Security lens applied because this exposes an operational dashboard and changes an authentication boundary.
- frps dashboard binds to `127.0.0.1:7500`, not `0.0.0.0`.
- nginx exposes the dashboard only through HTTPS vhost `frps-acorn.0xc1.wang` and enforces the existing agenix-managed Basic Auth htpasswd file.
- Targeted Nix eval confirms TCP `7500` is not in Acorn `networking.firewall.allowedTCPPorts`.
- No frp control-plane exposure changed; TCP `7000` behavior is unchanged.
- No plaintext frp token, dashboard password, Cloudflare token, or Basic Auth password was added to Git or Nix config.

## Residual Risks

- nginx Basic Auth is the only user-facing auth layer for this hostname because the user selected no Cloudflare Access automation for this task.
- The frps dashboard has no native frps dashboard username/password configured. This is acceptable only because the listener is loopback-only and nginx Basic Auth is the selected boundary.
- Live route behavior is not proven until Acorn switches to the merged config and ACME issuance completes.

## Required Deployment Follow-up

After PR merge and privileged Acorn access:

```bash
nixos-rebuild switch --flake .#acorn --target-host c1@8.159.128.125 --use-remote-sudo --fast --use-substitutes
```

Then verify that `7500` listens only on loopback, the HTTPS vhost returns Basic Auth `401`, and direct public TCP `7500` is unreachable.
