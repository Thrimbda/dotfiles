# Walkthrough: Aliyun Acorn HTTPS Firewall Ports

## Mode

implementation

## Problem

PR #112 made Vaultwarden/status staging loopback-only and closed `443`, but the host must keep public HTTPS available. The firewall also needs `2223` and `2224` in addition to the existing SSH/FRP ports.

## What Changed

- Firewall TCP ports are now `[22,443,2222,2223,2224,2225,7000,34197]`.
- `vault.0xc1.space` and `status-axiom.0xc1.wang` are HTTPS-only staged vhosts using nginx `onlySSL = true`.
- ACME remains disabled for both vhosts.
- Nginx preStart generates missing self-signed certificates under `/var/lib/nginx-selfsigned/<domain>/` before config validation.
- Public HTTP `80` remains closed.

## Verification

- Nix eval confirmed firewall ports, HTTPS vhost shape, no ACME/Docker units, and Docker disabled state.
- `nix build --impure --no-link .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel` passed.
- Generated nginx config shows only public `443 ssl` listeners for the staged domains.

## Residual Risk

The HTTPS certs are self-signed staging certs. Real ACME certs still require DNS/cutover readiness.
