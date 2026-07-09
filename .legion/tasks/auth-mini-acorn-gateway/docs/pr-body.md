## Summary

- Deploys `auth-mini` on Acorn at `auth.0xc1.wang`.
- Deploys `auth-mini-gateway` with per-origin gateway instances for `auth-gateway`, `status-axiom`, `opencode-axiom`, and `frps-acorn`.
- Replaces nginx Basic Auth on status/opencode/frps dashboard with gateway-backed `auth_request` while leaving Vaultwarden unchanged.

## Validation

- `nix-build --no-out-link -E 'with import <nixpkgs> {}; callPackage ./packages/auth-mini {}'`
- `nix-build --no-out-link -E 'with import <nixpkgs> {}; callPackage ./packages/auth-mini-gateway {}'`
- `nix build --impure --no-link .#nixosConfigurations.acorn.config.system.build.toplevel`
- targeted `nix eval` checks for firewall, gateway env, nginx protected locations, secret metadata, and Vaultwarden proxy shape
- generated nginx config inspection
- `git diff --check`

## Notes

- Gateway is per-origin because upstream validates returns against one `GATEWAY_PUBLIC_BASE_URL` and uses host-only cookies.
- Post-deploy work remains for DNS, ACME, auth-mini admin issuer/RP setup, and browser smoke checks.
