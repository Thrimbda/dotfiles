# Test Report: Axiom Critical Network Resilience

## Summary
Result: PASS with one expected manual-execution limitation.

The `axiom` NixOS system builds successfully. Generated systemd units, timers, SSH known host pinning, cloudflared metrics config, zram config, and Clash GUI/user-manager drop-ins match the RFC. Static unit and shell syntax checks pass. Safe live predicates for cloudflared readiness, autossh reverse endpoint identity, and Clash service/core health also pass.

Directly executing the generated healthcheck scripts as the current unprivileged user fails because they are root systemd oneshots that create `/run/axiom-healthchecks` and may restart system services. This is expected and not a deployment blocker; the generated units include `RuntimeDirectory=axiom-healthchecks` and `Type=oneshot`.

## Commands Run
### Full Build
- Command: `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel`
- Result: PASS
- Notes: Build completed with existing evaluation/deprecation warnings unrelated to this change.

- Command: `nix build --impure --no-link --print-out-paths .#nixosConfigurations.axiom.config.system.build.toplevel`
- Result: PASS
- Output path: `/nix/store/m8nadgvyhx6i7q5vd38c94amvbsi1f1v-nixos-system-axiom-25.11.20260203.e576e3c`

### Targeted Nix Evaluation
- Command: `nix eval --json .#nixosConfigurations.axiom.config.systemd.services.autossh-reverse-ssh.serviceConfig.OOMScoreAdjust`
- Result: PASS, output `-900`

- Command: `nix eval --json .#nixosConfigurations.axiom.config.systemd.timers.cloudflared-healthcheck.timerConfig`
- Result: PASS, output includes `OnBootSec=2m`, `OnUnitActiveSec=45s`, `RandomizedDelaySec=15s`, `Unit=cloudflared-healthcheck.service`

- Command: `nix eval --json '.#nixosConfigurations.axiom.config.programs.ssh.knownHosts."autossh-remote-8.159.128.125".publicKey'`
- Result: PASS, output is the pinned ED25519 key for `8.159.128.125`

- Command: `nix eval --json .#nixosConfigurations.axiom.config.zramSwap.enable`
- Result: PASS, output `true`

- Command: `nix eval --json .#nixosConfigurations.axiom.config.zramSwap.memoryMax`
- Result: PASS, output `8589934592`

- Command: `nix eval --json .#nixosConfigurations.axiom.config.systemd.services.cloudflared.serviceConfig.OOMScoreAdjust`
- Result: PASS, output `-850`

- Command: `nix eval --json .#nixosConfigurations.axiom.config.systemd.services.clash-verge.serviceConfig.MemoryLow`
- Result: PASS, output `"1G"`

- Command: `nix eval --json '.#nixosConfigurations.axiom.config.systemd.services."user@1000".serviceConfig.OOMScoreAdjust'`
- Result: PASS, output `0`

- Command: `nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///home/c1/dotfiles/.worktrees/axiom-critical-network-resilience"; in flake.nixosConfigurations.axiom.config.systemd.user.services."app-clash\\x2dverge@autostart".serviceConfig.OOMScoreAdjust'`
- Result: PASS, output `0`

### Generated Unit and Config Inspection
- `autossh-reverse-ssh.service`: contains `MemoryAccounting=true`, `MemoryMin=32M`, `MemoryLow=128M`, `OOMPolicy=stop`, `OOMScoreAdjust=-900`, `Restart=always`, `RestartSec=5s`.
- `cloudflared.service`: contains `MemoryMin=128M`, `MemoryLow=512M`, `OOMPolicy=stop`, `OOMScoreAdjust=-850`, `Restart=always`, `RestartSec=5s`.
- `clash-verge.service`: contains `MemoryMin=256M`, `MemoryLow=1G`, `OOMPolicy=stop`, `OOMScoreAdjust=-850`, `Restart=on-failure`, `RestartSec=5s`.
- `sshd.service`: contains `MemoryMin=32M`, `MemoryLow=128M`, `OOMPolicy=continue`, `OOMScoreAdjust=-900`.
- `user@1000.service.d/overrides.conf`: contains `OOMScoreAdjust=0`.
- `app-clash\x2dverge@autostart.service.d/overrides.conf`: contains `MemoryLow=256M`, `OOMScoreAdjust=0`, `Restart=on-failure`, `RestartSec=5s`.
- `cloudflared-healthcheck.timer`, `autossh-reverse-ssh-healthcheck.timer`, and `clash-verge-healthcheck.timer`: generated and wanted by `timers.target`.
- `/etc/cloudflared/config.yml`: includes `"metrics":"127.0.0.1:20241"` and preserves existing ingress entries.
- `/etc/ssh/ssh_known_hosts`: includes only the pinned `8.159.128.125` ED25519 key.
- `/etc/systemd/zram-generator.conf`: configures `zstd`, priority `100`, and capped size `min(20 / 100 * ram, 8589934592 / 1024 / 1024)`.

### Static Unit and Script Checks
- Command: `systemd-analyze verify <generated healthcheck services and timers>`
- Result: PASS

- Command: `bash -n <generated cloudflared/autossh/clash healthcheck scripts>`
- Result: PASS

### Safe Live Checks
- Command: temporary-known-hosts SSH check comparing remote `ssh-keyscan -p 2223 127.0.0.1` on `8.159.128.125` against local `/etc/ssh/ssh_host_ed25519_key.pub`
- Result: PASS, output `autossh remote endpoint key matches axiom host key`
- Notes: Used a temporary known_hosts file under `/tmp/opencode` and removed it. No write to user `~/.ssh/known_hosts`.

- Command: `curl --fail --silent --show-error --max-time 5 http://127.0.0.1:20241/ready`
- Result: PASS, output status `200` with `readyConnections=2`

- Command: live Clash service/core predicate equivalent to the healthcheck
- Result: PASS, output `clash-verge service/core currently healthy`

### Expected Limitation
- Command: direct execution of generated healthcheck scripts as the current user
- Result: EXPECTED FAILURE, output `mkdir: cannot create directory '/run/axiom-healthchecks': Permission denied`
- Reason: these scripts are designed to run as root under systemd oneshot units with `RuntimeDirectory=axiom-healthchecks` and permission to restart system services.

## Skipped
- `nixos-rebuild switch`: skipped by contract; deployment requires explicit approval after review.
- Live OOM stress testing: skipped by contract because it is destructive on the workstation.
- Healthcheck failure-threshold restart path: not forced live because it would intentionally restart production services; static syntax, unit verification, generated script inspection, and success-path predicates were used instead.

## Why These Checks
- The full NixOS build proves the configuration is valid and all generated units/scripts are buildable.
- Targeted Nix eval and generated file inspection prove the specific service-priority and timer claims made by the task.
- `systemd-analyze verify` and `bash -n` cover unit/script structural correctness without deploying.
- Safe live checks prove the current endpoints used by the healthchecks are valid without causing restarts or persistent SSH known-host mutation.
