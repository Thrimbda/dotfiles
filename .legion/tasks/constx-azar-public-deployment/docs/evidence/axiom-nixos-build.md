# Axiom NixOS Closure Build

## Scope

Build the Acorn system closure on Axiom only. Azar was not used as a build host or activated in this step.

## Input

- dotfiles commit: `404d7f9598520b752572c3583235a2f91c8ea2dc`
- staged source: `/home/c1/.cache/constx-azar-public-deployment/404d7f95`
- command:

```sh
nix build --impure --no-link --print-out-paths \
  '.#nixosConfigurations.acorn.config.system.build.toplevel'
```

## Result

- exit: `0`
- closure: `/nix/store/8d1bfd46v3yzrlfyknwv5aprf36yr9cs-nixos-system-acorn-26.05.7813.0dd31db7e6db`
- Axiom built 47 derivations and fetched Node 22.23.2 from the configured cache.

## Generated Config Checks

- `constxd.service` has the fixed release `ExecStart`, `c1:users`, private `/var/lib/constx` StateDirectory, Node 22 on `PATH`, loopback-only binary configuration, and the declared systemd hardening.
- Generated Nginx config contains `server_name constx.0xc1.wang`, ACME paths for that hostname, `/ -> http://127.0.0.1:3210`, `auth_request /_auth`, internal gateway login redirect, and the required 22 MiB / SSE / long-response proxy directives.
- The closure contains generated `auth-mini-gateway-constx` and `acme-*constx.0xc1.wang*` artifacts.

No target switch, DNS write, secret display, or model request occurred in this build.
