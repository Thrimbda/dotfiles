## Summary

- Enable Vaultwarden on `aliyun-acorn` for a staged dual-run migration.
- Keep the existing `acorn` Vaultwarden deployment unchanged.
- Add a new `aliyun-acorn` encrypted `vaultwarden-env.age` secret targeted at the `aliyunAcorn` recipient.

## Changes

- Import a new `hosts/aliyun-acorn/modules/vaultwarden.nix` module.
- Configure `aliyun-acorn` Vaultwarden service, backup path, agenix environment file, and `vault.0xc1.space` nginx routes.
- Add the `vaultwarden-env.age` rule to `hosts/aliyun-acorn/secrets/secrets.nix`.
- Add the encrypted `hosts/aliyun-acorn/secrets/vaultwarden-env.age` artifact.

## Tests

- PASS: `agenix -d vaultwarden-env.age -i /home/c1/.ssh/id_ed25519 > /dev/null`
- PASS: targeted Nix eval confirmed `aliyun-acorn` service/vhost/secret/fail2ban shape and `acorn` still enabled.
- PASS: `nix eval --impure .#nixosConfigurations.aliyun-acorn.config.services.vaultwarden.enable`
- PASS: `nix eval --impure .#nixosConfigurations.aliyun-acorn.config.age.secrets.vaultwarden-env.owner`
- PASS: `nix eval --impure .#nixosConfigurations.aliyun-acorn.config.services.nginx.virtualHosts."vault.0xc1.space".locations."/notifications/hub".proxyPass`
- PASS: `nix build --impure --no-link .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel`

Note: pre-staging `.#` eval/build initially hit the expected Git-backed flake source caveat for an untracked new module; the post-staging `.#` eval/build passed.

## Review / security

- RFC review: PASS.
- Change review: PASS; no blocking findings.
- No private key or plaintext secret file is staged.
- Secret decryptability was verified with output redirected to `/dev/null`; plaintext was not printed or inspected.

## Residual risks

- No live deployment was performed.
- DNS/ACME readiness and post-deploy service checks remain operational follow-up.
- Dual-running the same domain can diverge Vaultwarden data if traffic is split without a migration or ownership plan.

## Rollback

Revert this PR, or remove the `aliyun-acorn` Vaultwarden module/import, secret rule, and encrypted secret file. `acorn` remains unchanged.
