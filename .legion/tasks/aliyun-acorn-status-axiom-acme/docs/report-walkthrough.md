# Walkthrough

## Summary

`status-axiom.0xc1.wang` has been converted from staged self-signed TLS to Cloudflare DNS-01 ACME in the `aliyun-acorn` NixOS config.

## Changed Files

- `hosts/aliyun-acorn/default.nix`: removes the status self-signed staging vhost and adds ACME-backed nginx/ACME config for `status-axiom.0xc1.wang`.
- `.legion/wiki/decisions.md`: records DNS-01 ACME as the current status hostname policy.

## Verification

- Nix evaluation and build pass.
- The evaluated config enables `acme-status-axiom.0xc1.wang.service` and `acme-renew-status-axiom.0xc1.wang.timer`.
- Live deployment is blocked on remote sudo/root access, not on Nix configuration validity.
