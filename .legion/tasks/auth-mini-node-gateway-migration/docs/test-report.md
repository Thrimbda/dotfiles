# Test Report

## Result

PASS. No live deployment was performed.

## Checks

- `nix build --no-link -L .#packages.x86_64-linux.auth-mini-gateway`
  - PASS. The pinned gateway package builds successfully.
- `nix build --impure --no-link -L .#nixosConfigurations.axiom.config.system.build.toplevel`
  - PASS. The Axiom toplevel builds with both new gateway units and the updated FRP configuration.
- Targeted `nix eval --impure` assertions
  - PASS. Axiom gateways use ports `7779/7780` and upstreams `8080/4096`; FRP targets the gateway ports; Acorn keeps only `auth-gateway` and `frps-acorn`; status/OpenCode vhosts target `18080/18081`; internal ports remain absent from both firewalls; the Axiom secret is mode `0400`; gateway units drop capabilities and disable core dumps.
- `git diff --check`
  - PASS.

The existing unrelated xorg rename warnings appeared during the Axiom build and did not affect the result. No Acorn closure build, switch, activation, or deployment was run.
