# Log: Aliyun Acorn Vaultwarden ACME Staging Fix

## 2026-07-01

- User reported that `nixos-rebuild` now hangs every time after the Vaultwarden dual-run change.
- Diagnosis: `hosts/aliyun-acorn/modules/vaultwarden.nix` set `enableACME = true` and `forceSSL = true` for `vault.0xc1.space` during a staging/dual-run phase.
- Evidence: evaluated `nginx.service` has `After=` and `Wants=` for `acme-vault.0xc1.space.service`; evaluated ACME units include `acme-vault.0xc1.space.service`, `acme-order-renew-vault.0xc1.space.service`, and `acme-renew-vault.0xc1.space.timer`.
- Root cause hypothesis: because `vault.0xc1.space` is not routed to `aliyun-acorn` yet, ACME HTTP-01 renewal/order can block activation and make `nixos-rebuild switch` appear stuck.
- Decision: fix the staging config by keeping Vaultwarden service/secret/reverse proxy, but not enabling automatic TLS/ACME for `vault.0xc1.space` until DNS/cutover is ready.
- Worktree envelope opened at `.worktrees/aliyun-acorn-vaultwarden-acme-staging-fix` on branch `legion/aliyun-acorn-vaultwarden-acme-staging-fix` from `origin/master`.

### Live Host Inspection

- Connected to `aliyun-acorn` via `c1@8.159.128.125`; remote hostname reported as `iZuf604bomkhxctt093h57Z`.
- Remote `/home/c1/dotfiles` is on `master...origin/master` at `cf945a0c feat(aliyun-acorn): add vaultwarden dual-run (#111)`.
- Active `/run/current-system` is `/nix/store/f830mhp8czwb4b1sqyyb0rjlv6ayp2gr-nixos-system-aliyun-acorn-25.11.20260203.e576e3c`.
- Active system does not have `vaultwarden.service`, `acme-vault.0xc1.space.service`, or `acme-order-renew-vault.0xc1.space.service`.
- `nginx.service` is active from the older generation.
- `systemctl --failed` shows only `acme-order-renew-status-axiom.0xc1.wang.service`.
- `acme-order-renew-status-axiom.0xc1.wang.service` fails quickly with Let's Encrypt DNS NXDOMAIN for `status-axiom.0xc1.wang`; logs explicitly say self-signed certs remain and dependent services still start.
- Historical sudo logs show some `nixos-rebuild --flake /home/c1/dotfiles#aliyun-acorn switch` runs lasting minutes to ~41 minutes, but current system did not advance to a Vaultwarden generation.
- No active `nixos-rebuild`, `switch-to-configuration`, Nix build, or systemd jobs were present before repro.
- A non-switching remote `nix build --dry-run --no-link .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel` against PR #111 produced no output for 180 seconds and timed out from this client.
- After that dry-run timeout, new SSH attempts to `8.159.128.125:22` timed out during banner exchange, so remote follow-up is blocked until the host recovers or another console path is available.

### Revised Diagnosis

- The original `vault.0xc1.space` ACME activation hypothesis is plausible from local Nix evaluation but not supported as the observed live hang yet, because the active host has not reached a generation containing those units.
- The observed symptom is currently more consistent with Nix evaluation/build/download resource pressure or a stalled Nix/substituter path before activation.
- User confirmed the machine is low-end, is not intended for development, and does not need desktop software.
- Decision: ship a low-resource server profile fix rather than only an ACME fix.

### Implementation

- Removed `modules.dev.node`, `modules.dev.deno`, `modules.dev.rust`, and `modules.dev.python` from `hosts/aliyun-acorn/default.nix`.
- Removed `modules.shell.adl`, `modules.shell.direnv`, and `modules.shell.gnupg` from `hosts/aliyun-acorn/default.nix`.
- Removed `modules.services.docker` and forced Docker boot enablement off in `hosts/aliyun-acorn/default.nix`.
- Forced `programs.nix-ld.enable = false` for `aliyun-acorn`, avoiding global graphical/game compatibility libraries on this server.
- Disabled local documentation outputs for `aliyun-acorn`.
- Limited Nix to `max-jobs = 1`, `cores = 1`, and `http-connections = 4` on `aliyun-acorn`.
- Changed OpenSSH from socket activation to normal daemon mode with `services.openssh.startWhenNeeded = false`.
- Cleared the inherited unsupported `GSSAPIAuthentication no` OpenSSH extra config for `aliyun-acorn`; live logs showed that line emitted an unsupported-option warning on each connection.
- Disabled ACME/forced SSL for `status-axiom.0xc1.wang` until DNS is ready.
- Disabled ACME/forced SSL for `vault.0xc1.space` until DNS/cutover is ready.
- Restricted both staged nginx vhosts to `127.0.0.1:80` so auth-bearing HTTP surfaces are only available locally or through SSH tunneling.
- Forced the firewall TCP ports to `[22 2222 2225 7000 34197]`, removing public `80/443` until public HTTP/TLS cutover is ready.

### Local Verification

- `nix eval --impure --json .#nixosConfigurations.aliyun-acorn.config.services.vaultwarden.enable` -> `true`.
- `nix eval --impure --json .#nixosConfigurations.aliyun-acorn.config.systemd.units --apply 'units: builtins.filter (name: builtins.match ".*(vault|status-axiom).*acme.*|.*acme.*(vault|status-axiom).*" name != null) (builtins.attrNames units)'` -> `[]`.
- `nix eval --impure --json .#nixosConfigurations.aliyun-acorn.config.services.openssh --apply 's: { enable = s.enable; startWhenNeeded = s.startWhenNeeded; extraConfig = s.extraConfig; }'` -> `{"enable":true,"extraConfig":"","startWhenNeeded":false}`.
- `nix eval --impure --json .#nixosConfigurations.aliyun-acorn.config.nix.settings --apply 's: { maxJobs = s.max-jobs or null; cores = s.cores or null; httpConnections = s.http-connections or null; }'` -> `{"cores":1,"httpConnections":4,"maxJobs":1}`.
- `nix eval --impure --json .#nixosConfigurations.aliyun-acorn.config.user.packages --apply 'ps: builtins.map (p: p.name or "unknown") ps'` -> `["editorconfig-core-c-0.12.9","lazygit-0.56.0","neovim-0.11.5"]`.
- `nix eval --impure --json .#nixosConfigurations.aliyun-acorn.config.virtualisation.docker --apply 'd: { enable = d.enable; enableOnBoot = d.enableOnBoot; }'` -> `{"enable":false,"enableOnBoot":false}`.
- `nix eval --impure --json .#nixosConfigurations.aliyun-acorn.config.programs.nix-ld.enable` -> `false`.
- `nix eval --impure --json .#nixosConfigurations.aliyun-acorn.config.systemd.units --apply 'units: { acme = builtins.filter (name: builtins.match ".*acme.*" name != null) (builtins.attrNames units); docker = builtins.filter (name: builtins.match ".*docker.*" name != null) (builtins.attrNames units); sshd = builtins.filter (name: builtins.match ".*ssh.*" name != null) (builtins.attrNames units); }'` -> `{"acme":[],"docker":[],"sshd":["sshd-keygen.service","sshd.service","sshd@.service"]}`.
- `nix eval --impure --json .#nixosConfigurations.aliyun-acorn.config.networking.firewall.allowedTCPPorts` -> `[22,2222,2225,7000,34197]`.
- Generated nginx config inspection showed only `listen 127.0.0.1:80` for `status-axiom.0xc1.wang` and `vault.0xc1.space`.
- `nix build --impure --no-link .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel` passed after the local-only vhost/firewall update.
- Closure comparison: slim branch `3.2 GiB`; current PR #111 baseline in main checkout `5.5 GiB`; reduction about `2.3 GiB`.
