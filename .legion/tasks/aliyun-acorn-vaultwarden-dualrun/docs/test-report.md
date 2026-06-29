# Test Report: Aliyun Acorn Vaultwarden Dual Run

**Date**: 2026-06-30
**Stage**: verify-change
**Result**: PASS

## Inputs Reviewed

- `.legion/tasks/aliyun-acorn-vaultwarden-dualrun/plan.md`
- `.legion/tasks/aliyun-acorn-vaultwarden-dualrun/docs/rfc.md`
- `.legion/tasks/aliyun-acorn-vaultwarden-dualrun/docs/review-rfc.md`
- Changed target-host files under `hosts/aliyun-acorn`:
  - `hosts/aliyun-acorn/default.nix`
  - `hosts/aliyun-acorn/modules/vaultwarden.nix`
  - `hosts/aliyun-acorn/secrets/secrets.nix`
  - `hosts/aliyun-acorn/secrets/vaultwarden-env.age` was not printed; it was validated only by decrypting to `/dev/null`.

## Executed Checks

| Check | Command | Result | Evidence / Notes |
|---|---|---:|---|
| Target secret decryptability | From `hosts/aliyun-acorn/secrets`: `agenix -d vaultwarden-env.age -i /home/c1/.ssh/id_ed25519 > /dev/null` | PASS | Command exited successfully and printed no plaintext. This directly verifies the new encrypted file can be decrypted by the target identity. |
| Required flake eval syntax | `nix eval --impure .#nixosConfigurations.aliyun-acorn.config.services.vaultwarden.enable` | FAIL / environment-source caveat | Failed because the Git-backed `.#` flake source omitted the new untracked `hosts/aliyun-acorn/modules/vaultwarden.nix` file. This is not a NixOS option/config failure; it is a pre-staging worktree source snapshot issue. |
| Target service/vhost/secret/fail2ban/acorn shape | `nix eval --impure --json --expr 'let flake = builtins.getFlake "path:/home/c1/dotfiles/.worktrees/aliyun-acorn-vaultwarden-dualrun"; ... in { aliyun = ...; acorn = ...; }'` | PASS | Evaluated the live working tree with `path:` so untracked new files were included. Confirmed `aliyun-acorn` has Vaultwarden module + service enabled, `/backup/vaultwarden`, `environmentFile` pointing at the agenix secret, expected service settings, nginx `vault.0xc1.space` routes, `vaultwarden:vaultwarden` `0400` secret ownership/mode, fail2ban jails/filters, and `acorn` still has Vaultwarden enabled. |
| Target agenix rule | `nix eval --impure --json --expr 'let rules = import /home/c1/dotfiles/.worktrees/aliyun-acorn-vaultwarden-dualrun/hosts/aliyun-acorn/secrets/secrets.nix; in { vaultwardenRulePresent = rules ? "vaultwarden-env.age"; vaultwardenRuleMatchesAliyunAcornOnly = rules."vaultwarden-env.age".publicKeys == rules."nginx-status-htpasswd.age".publicKeys; }'` | PASS | Returned both booleans as `true`, confirming the new rule exists and matches the existing `aliyunAcorn`-only recipient pattern. |
| Required toplevel build syntax | `nix build --impure --no-link .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel` | FAIL / environment-source caveat | Same Git-backed `.#` source issue: the untracked new module was absent from the flake snapshot. |
| Working-tree toplevel build | `nix build --impure --no-link "path:$PWD#nixosConfigurations.aliyun-acorn.config.system.build.toplevel"` | PASS | Built the `aliyun-acorn` NixOS toplevel successfully with the current working-tree content and without creating a result symlink. |
| Post-staging plain service eval | `nix eval --impure .#nixosConfigurations.aliyun-acorn.config.services.vaultwarden.enable` | PASS | Returned `true` after intended new files were staged/tracked for the Git flake source. |
| Post-staging plain secret owner eval | `nix eval --impure .#nixosConfigurations.aliyun-acorn.config.age.secrets.vaultwarden-env.owner` | PASS | Returned `"vaultwarden"`. |
| Post-staging plain nginx websocket eval | `nix eval --impure .#nixosConfigurations.aliyun-acorn.config.services.nginx.virtualHosts."vault.0xc1.space".locations."/notifications/hub".proxyPass` | PASS | Returned `"http://127.0.0.1:3012"`. |
| Post-staging plain toplevel build | `nix build --impure --no-link .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel` | PASS | Built the `aliyun-acorn` NixOS toplevel successfully after intended new files were staged/tracked. |

## Shape Details Confirmed by Nix Eval

- `modules.services.vaultwarden.enable = true`
- `services.vaultwarden.enable = true`
- `services.vaultwarden.backupDir = "/backup/vaultwarden"`
- `services.vaultwarden.environmentFile = [ config.age.secrets."vaultwarden-env".path ]`
- Vaultwarden config:
  - `domain = "https://vault.0xc1.space"`
  - `rocketPort = 8000`
  - `websocketEnabled = true`
  - `signupsAllowed = false`
  - `invitationsAllowed = true`
  - `loginRatelimitSeconds = 30`
- `age.secrets."vaultwarden-env"`:
  - `owner = "vaultwarden"`
  - `group = "vaultwarden"`
  - `mode = "0400"`
- `services.nginx.virtualHosts."vault.0xc1.space"`:
  - `forceSSL = true`
  - `enableACME = true`
  - `http2 = true`
  - `root = "/srv/www/vault.0xc1.space"`
  - `extraConfig` includes `client_max_body_size 64M;`
  - `/notifications/hub/negotiate -> http://127.0.0.1:8000` with websockets
  - `/notifications/hub -> http://127.0.0.1:3012` with websockets
  - `/ -> http://127.0.0.1:8000`
- Fail2ban:
  - `services.fail2ban.enable = true`
  - `vaultwarden` jail present with `filter = vaultwarden`, `port = 80,443,8000`, `maxretry = 5`
  - `vaultwarden-admin` jail present with `filter = vaultwarden-admin`, `maxretry = 3`, `bantime = 14400`, `findtime = 14400`
  - Both Vaultwarden fail2ban filter files are present in `environment.etc`
- Existing `acorn` configuration remains enabled:
  - `acorn.modules.services.vaultwarden.enable = true`
  - `acorn.services.vaultwarden.enable = true`

## Rationale

- Secret validation used `agenix -d ... > /dev/null` because decryptability with the target private key is the strongest check for the wrong-recipient risk and avoids exposing plaintext.
- Targeted Nix eval was chosen before the full build because it directly proves the acceptance-critical config shape: service, nginx routes, secret metadata, fail2ban, and `acorn` preservation.
- The toplevel build was still run because it validates option types, module composition, service units, and build closure beyond the targeted eval assertions.
- `path:$PWD#...` was used before staging to validate the live working tree. After staging the intended files, the plain `.#...` eval/build forms also passed and are the final delivery evidence.

## Skipped Checks

- No live deployment checks were run. This task is repository verification only; runtime checks of `vaultwarden.service`, `nginx.service`, `fail2ban.service`, ACME issuance, and `/run/agenix/vaultwarden-env` ownership remain post-deploy work.

## Residual Risks

- The decryptability check proves the target key can decrypt the file but does not print or inspect secret contents by design.
- No DNS, ACME, database, or data-migration validation was performed. Dual-run traffic routing and data ownership remain operational cutover risks outside this config-only task.
