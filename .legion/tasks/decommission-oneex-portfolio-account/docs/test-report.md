# Test Report: Minimal 1Ex Portfolio Adapter Undeployment

> **Result**: FINAL PASS
> **PR / merge revision**: [#203](https://github.com/Thrimbda/dotfiles/pull/203), MERGED as `df26dce7f6b0652172cf5d604527f18d73cd76a5`
> **Active generation**: `/nix/store/aasj72hy0vdl7sbgdgfib54x4bnhgggc-nixos-system-acorn-26.05.7813.0dd31db7e6db`
> **Verification origin**: Axiom
> **Date**: 2026-08-24

## Decision

The merged one-line Acorn undeploy was built on Axiom, activated successfully on Acorn, and runtime-verified. The adapter serving boundary is absent, all nine checked services are active, no failed unit exists, and the intentionally retained age secret was checked only for existence.

## Merged Scope

Command: `git diff --numstat df26dce7f6b0652172cf5d604527f18d73cd76a5^1 df26dce7f6b0652172cf5d604527f18d73cd76a5 -- . ':(exclude).legion/**'`

**PASS:** `0 1 hosts/acorn/default.nix`; the only production hunk is:
```diff
-    ./modules/oneex-portfolio-adapter.nix
```
The adapter module, package, Acorn secrets, global agenix module, and all other production files are unchanged.

## Deployment

The successful deployment ran from the merged checkout on Axiom using exactly:
```sh
nixos-rebuild switch --flake .#acorn --target-host c1@8.159.128.125 --build-host localhost --sudo --ask-sudo-password --use-substitutes -L
```
`--build-host localhost` referred to Axiom. Build/realization, transfer, and activation passed; no Nix evaluation or build ran on Acorn. Final Acorn verification consisted only of read-only commands initiated from Axiom.

## Final Verification

| Check | Exact command | Result |
| --- | --- | --- |
| Active generation | `ssh -o BatchMode=yes -o ConnectTimeout=10 c1@8.159.128.125 readlink -f /run/current-system`<br>`ssh -o BatchMode=yes -o ConnectTimeout=10 c1@8.159.128.125 nixos-version --json` | Generation matched the path above; metadata reported `configurationRevision=df26dce7f6b0652172cf5d604527f18d73cd76a5`. |
| Units absent | `ssh -o BatchMode=yes -o ConnectTimeout=10 c1@8.159.128.125 systemctl show oneex-portfolio-adapter.service acme-1ex-portfolio.0xc1.wang.service acme-1ex-portfolio.0xc1.wang.timer --property=Id --property=LoadState --property=ActiveState --property=SubState --no-pager` | All three: `LoadState=not-found`, `ActiveState=inactive`, `SubState=dead`. |
| Process / TCP `8090` | `ssh -o BatchMode=yes -o ConnectTimeout=10 c1@8.159.128.125 'if pgrep -af "[o]neex-portfolio-adapter"; then exit 1; else test "$?" -eq 1; fi'`<br>`ssh -o BatchMode=yes -o ConnectTimeout=10 c1@8.159.128.125 'ss -H -ltn "sport = :8090"'` | Process assertion passed with no match; listener query returned no row. |
| Active nginx config | `ssh -o BatchMode=yes -o ConnectTimeout=10 c1@8.159.128.125 systemctl show nginx.service --property=ExecStart --no-pager`<br>`ssh -o BatchMode=yes -o ConnectTimeout=10 c1@8.159.128.125 'if grep -Fq -e "1ex-portfolio.0xc1.wang" -e "8090" /nix/store/1q8yqa960xyf7zwihwxs8cz2xb51zmrh-nginx.conf; then exit 1; else test "$?" -eq 1; fi'` | `ExecStart` used that store config; neither adapter hostname nor `8090` was present. |
| TLS / public fallback | `curl --noproxy '*' --silent --show-error --output /dev/null --connect-timeout 10 --max-time 20 https://1ex-portfolio.0xc1.wang/`<br>`curl --noproxy '*' --insecure --silent --show-error --output /dev/null --write-out '%{http_code}\n' --connect-timeout 10 --max-time 20 https://1ex-portfolio.0xc1.wang/` | Verified TLS failed with curl error 60 (hostname mismatch); the credential-free diagnostic returned default `404`. |
| Retained secret | `ssh -o BatchMode=yes -o ConnectTimeout=10 c1@8.159.128.125 test -e /run/agenix/oneex-portfolio-adapter-env` | Existence-only check passed; no target or content was printed, opened, copied, or changed. |
| Nine services | `ssh -o BatchMode=yes -o ConnectTimeout=10 c1@8.159.128.125 systemctl is-active nginx.service frps.service rustdesk-relay.service rustdesk-signal.service vaultwarden.service auth-mini.service auth-mini-gateway-auth-gateway.service auth-mini-gateway-frps-acorn.service sshd.service` | Returned `active` for all nine services in order. |
| Failed units | `ssh -o BatchMode=yes -o ConnectTimeout=10 c1@8.159.128.125 systemctl --failed --no-legend --plain` | No rows. |

No browser, 1Exchange API, auth-mini API, credential, or secret-content access occurred. Outside the mandated deployment, verification did not mutate host, account, service, file, DNS, certificate, credential, or secret state.

## Residuals

- The runtime secret, ciphertext/declaration, dormant adapter module, and package snapshot remain and could support a future re-import.
- DNS still reaches Acorn; verified clients reject the hostname, while clients bypassing TLS verification receive the default `404`.
- Older NixOS generations and store paths retain rollback potential.
- External 1Exchange/auth-mini metadata and credentials were not erased or revoked; this proves Acorn undeployment, not external account retirement.

## Final Decision

**FINAL PASS. No blocker remains for the scoped Acorn undeployment.**

References: `rfc.md`, `research.md`, `review-rfc.md`, `review-change.md`, `../plan.md`, `../log.md`.
