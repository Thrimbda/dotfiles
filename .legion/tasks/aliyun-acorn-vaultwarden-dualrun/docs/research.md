# Research Notes

## Problem Restatement

- Add Vaultwarden to `aliyun-acorn` for a staged dual-run migration while keeping the existing `acorn` deployment intact.
- The deployment is NixOS host configuration plus agenix secret material; the secret must be re-encrypted for the `aliyun-acorn` recipient.

## Relevant Code / Entry Points

- `hosts/acorn/default.nix` imports `./modules/vaultwarden.nix`.
- `hosts/acorn/modules/vaultwarden.nix` enables the shared Vaultwarden service module, declares `age.secrets.vaultwarden-env`, configures `services.vaultwarden`, and defines nginx vhost `vault.0xc1.space`.
- `hosts/acorn/secrets/secrets.nix` declares the existing `vaultwarden-env.age` recipient.
- `hosts/aliyun-acorn/default.nix` currently imports only the qemu guest profile and has no Vaultwarden import.
- `hosts/aliyun-acorn/secrets/secrets.nix` currently declares `frp-token.age`, `nginx-status-htpasswd.age`, and `status-basic-auth-password.age` only.
- `modules/services/vaultwarden.nix` provides the shared `modules.services.vaultwarden` option, enables `services.vaultwarden`, adds the user to the `vaultwarden` group, and configures fail2ban filters/jails.
- `modules/agenix.nix` imports host-local `secrets/secrets.nix` through `modules.agenix.dirs`, so `aliyun-acorn` needs its own `vaultwarden-env.age` declaration and file.

## Existing Conventions

- Host-specific service wiring can live under `hosts/<host>/modules/*.nix` and be imported from that host's `default.nix`.
- Host-specific agenix rules live under `hosts/<host>/secrets/secrets.nix`.
- `age.secrets.<name>` ownership/mode overrides are declared in host config near the service that consumes the secret.

## Historical Decisions

- `.legion/tasks/acorn/context.md` records prior Vaultwarden secret recovery work and the decision to prioritize the agenix decrypt chain before changing service parameters.
- The same history records explicit tightening of `vaultwarden-env` ownership/mode to `vaultwarden:vaultwarden` and `0400`.

## Constraints & Non-goals

- Keep `acorn` Vaultwarden configuration unchanged for dual-run.
- Do not change DNS, ACME account settings, Vaultwarden tokens, SMTP credentials, database credentials, or vault data.
- Do not persist Vaultwarden secret plaintext in repo files, logs, or chat output.
- Do not deploy with `nixos-rebuild switch` in this task.

## Risks & Pitfalls

- Copying the old `.age` file would not make it decryptable by `aliyun-acorn` and may only fail at activation time.
- Nix evaluation can prove the file path and option graph, but not that the encrypted secret decrypts on the target unless decryptability is checked with the target identity.
- Running `vault.0xc1.space` on two hosts is only a safe staged state if external routing is controlled and data divergence is understood.
- ACME issuance on `aliyun-acorn` may fail until DNS routes `vault.0xc1.space` to that host.

## Unknowns

- None blocking implementation after user provided `./acorn_id_ed25519` as the old acorn decrypt identity and confirmed target encryption should use `/home/c1/.ssh/id_ed25519`.

## References

- Plan: `.legion/tasks/aliyun-acorn-vaultwarden-dualrun/plan.md`
- Existing service: `hosts/acorn/modules/vaultwarden.nix`
- Target host: `hosts/aliyun-acorn/default.nix`
- Target secrets rules: `hosts/aliyun-acorn/secrets/secrets.nix`
- Agenix import behavior: `modules/agenix.nix`
