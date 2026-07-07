# Walkthrough

## Summary

Adds a new parallel `opencode-axiom.0xc1.wang` route to Axiom OpenCode through Axiom frpc, Aliyun Acorn frps/nginx, Cloudflare proxied DNS, Cloudflare Access, and DNS-01 ACME.

The existing `opencode-axiom.0xc1.space` Cloudflared route is not changed or migrated.

## What Changed

- `hosts/axiom/default.nix`: adds frpc proxy `axiom-opencode-http` from local OpenCode `127.0.0.1:4096` to Acorn remote TCP `18081`.
- `hosts/aliyun-acorn/default.nix`: adds nginx vhost `opencode-axiom.0xc1.wang` with `onlySSL`, `useACMEHost`, websocket proxying, and Basic Auth.
- `hosts/aliyun-acorn/default.nix`: adds Cloudflare DNS-01 ACME cert config for `opencode-axiom.0xc1.wang`.
- `.legion/wiki/decisions.md`: records the new frp backend port and the required Access plus origin Basic Auth boundary.
- `.legion/tasks/axiom-opencode-wang-frp/**`: records design, verification, review, and deployment handoff evidence.

## External State

- Cloudflare DNS now has `opencode-axiom.0xc1.wang` as a proxied `A` record to `8.159.128.125`.
- Cloudflare Access has self-hosted app `opencode-axiom-wang` for `opencode-axiom.0xc1.wang`.
- Access policy allows exact emails `c1@ntnl.io`, `siyuan.arc@gmail.com`, `froggy2818@gmail.com`, and `wangpeiguangwpg@gmail.com`, and requires the Google IdP `399adc69-d770-4685-8acf-cdea3acca230`.

## Verification

- Targeted Nix eval confirms the Axiom frpc proxy is `127.0.0.1:4096 -> 18081`.
- Targeted Nix eval confirms Acorn nginx proxies `opencode-axiom.0xc1.wang` to `http://127.0.0.1:18081`, enables websockets, and has Basic Auth configured.
- Targeted Nix eval confirms Acorn ACME uses Cloudflare DNS and `useACMEHost = "opencode-axiom.0xc1.wang"`.
- Targeted Nix eval confirms `18081` is not opened in Acorn NixOS firewall allowed TCP ports.
- `nix build .#nixosConfigurations.axiom.config.system.build.toplevel --dry-run` passed.
- `nix build .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel --dry-run` passed.
- `nix build .#nixosConfigurations.axiom.config.system.build.toplevel --no-link` passed.
- `nix build .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel --no-link` passed.
- `git diff --check` passed.
- Cloudflare API verified DNS and Access state.

## Deployment Status

Not deployed live in this task turn. Acorn activation requires privileged sudo/root access; the previous remote switch attempt reached closure copy but stopped at sudo password/TTY, and root SSH key login was denied.

After merge and privileged access, switch both hosts and verify public Access behavior plus direct-origin Basic Auth.
