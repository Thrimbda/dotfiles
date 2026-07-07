# Walkthrough

Mode: implementation.

## Summary

Exposes the Acorn frps dashboard at `frps-acorn.0xc1.wang` through Acorn nginx, protected by nginx Basic Auth, while keeping the frps dashboard HTTP listener on Acorn loopback only.

## What Changed

- `hosts/acorn/default.nix`: enables frps dashboard `webServer` on `127.0.0.1:7500`.
- `hosts/acorn/default.nix`: adds nginx vhost `frps-acorn.0xc1.wang` with `onlySSL`, `useACMEHost`, and Basic Auth.
- `hosts/acorn/default.nix`: adds Cloudflare DNS-01 ACME cert config for `frps-acorn.0xc1.wang`.
- `.legion/wiki/decisions.md`: records that TCP `7500` is a loopback-only dashboard backend and must not be publicly opened.
- Cloudflare DNS: created/updated DNS-only `A frps-acorn.0xc1.wang -> 8.159.128.125`.

## Security Boundary

- Browser-facing auth is nginx Basic Auth from the existing agenix-managed htpasswd secret.
- frps dashboard listens only on `127.0.0.1:7500`.
- TCP `7500` is not opened in Acorn NixOS firewall by this change.
- frps control TCP `7000` and existing frp tunnels are unchanged.
- No new plaintext dashboard password or token was added.

## Verification

- Targeted Nix eval confirms frps dashboard config is `{ addr = "127.0.0.1"; port = 7500; }`.
- Targeted Nix eval confirms nginx proxies `frps-acorn.0xc1.wang` to `http://127.0.0.1:7500` with Basic Auth configured.
- Targeted Nix eval confirms `useACMEHost = "frps-acorn.0xc1.wang"` and ACME DNS provider `cloudflare`.
- Targeted Nix eval confirms TCP `7500` is not in Acorn firewall allowed TCP ports.
- `nix build .#nixosConfigurations.acorn.config.system.build.toplevel --dry-run` passed.
- `nix build .#nixosConfigurations.acorn.config.system.build.toplevel --no-link` passed.
- `git diff --check` passed.
- Cloudflare API verified DNS-only A record state.

## Deployment Status

Not deployed live in this task turn. Acorn activation requires privileged sudo/root access; previous Acorn activation attempts were blocked by sudo password/TTY and denied root key login.

After merge and privileged access, switch Acorn and verify loopback listener, Basic Auth behavior, and public direct `7500` inaccessibility.
