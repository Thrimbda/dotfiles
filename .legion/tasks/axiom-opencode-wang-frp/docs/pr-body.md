## Summary

- add parallel `opencode-axiom.0xc1.wang` frp/nginx route for Axiom OpenCode
- keep existing `opencode-axiom.0xc1.space` Cloudflared route unchanged
- protect the new route with Cloudflare Access plus Acorn nginx Basic Auth
- add Cloudflare DNS-01 ACME config and record Legion verification/review evidence

## Verification

- `nix build .#nixosConfigurations.axiom.config.system.build.toplevel --dry-run`
- `nix build .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel --dry-run`
- `nix build .#nixosConfigurations.axiom.config.system.build.toplevel --no-link`
- `nix build .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel --no-link`
- `git diff --check`
- targeted Nix evals for frpc proxy, nginx vhost, ACME provider, and Acorn firewall
- Cloudflare API verification for proxied DNS record and Access app/policy

## Deployment Note

Live deployment still requires privileged host switches on Axiom and `aliyun-acorn`. Acorn activation is currently blocked by remote sudo/root access.
