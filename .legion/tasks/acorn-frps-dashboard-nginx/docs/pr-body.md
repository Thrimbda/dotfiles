## Summary

- enable Acorn frps dashboard on loopback `127.0.0.1:7500`
- expose it through nginx as `frps-acorn.0xc1.wang` with Basic Auth
- add DNS-01 ACME config for the dashboard hostname
- create/update Cloudflare DNS-only `A frps-acorn.0xc1.wang -> 8.159.128.125`
- record Legion verification, security review, and wiki evidence

## Verification

- `nix build .#nixosConfigurations.acorn.config.system.build.toplevel --dry-run`
- `nix build .#nixosConfigurations.acorn.config.system.build.toplevel --no-link`
- `git diff --check`
- targeted Nix evals for frps dashboard listener, nginx proxy/auth, ACME provider, and firewall non-exposure
- Cloudflare API verification for DNS-only A record

## Deployment Note

Live deployment still requires privileged Acorn switch access. After deployment, verify that `7500` listens only on loopback, HTTPS returns nginx Basic Auth `401`, and public direct TCP `7500` is unreachable.
