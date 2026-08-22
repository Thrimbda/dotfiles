# Test Report: Acorn vnStat Traffic Accounting

## Verdict

PASS

## Rationale

The configuration evaluation proves the desired NixOS option is enabled. The remote rebuild proves the closure was built on Axiom and activated on Acorn. Host-side checks prove the daemon started, registered the primary interface, and did not disrupt the existing public-service baseline.

## Executed Checks

| Check | Result | Evidence |
| --- | --- | --- |
| `nix eval .#nixosConfigurations.acorn.config.services.vnstat.enable` | PASS | Returned `true`. |
| Axiom-to-Acorn `nixos-rebuild switch --flake .#acorn --target-host c1@8.159.128.125 --build-host localhost --sudo --ask-sudo-password --use-substitutes -L` | PASS | Built locally on Axiom, copied the closure to Acorn, activated it, and reported `the following new units were started: vnstat.service`. The authorized password was supplied through standard input and is intentionally omitted. |
| `systemctl is-active vnstat` on Acorn | PASS | Returned `active`. |
| `vnstat --days` on Acorn | PASS with expected warm-up | Registered `ens5`; its database was created at 2026-08-22 12:31:22 and has no sample yet. |
| Existing service health | PASS | `nginx`, `frps`, `rustdesk-relay`, `rustdesk-signal`, `vaultwarden`, `auth-mini`, `oneex-portfolio-adapter`, `auth-mini-gateway-auth-gateway`, and `auth-mini-gateway-frps-acorn` all returned `active`. |

## Notes

`vnstat` requires a collection interval before it can show day or month totals. This is normal for a newly created database and does not affect daemon health or future persistence. No historic August traffic can be reconstructed.
