# Test Report: Axiom Autossh C1 Runtime Fix

## Summary

PASS for generated configuration, build, service-style SSH authentication, and a temporary reverse-tunnel endpoint identity smoke test.

## Commands

```bash
nix eval --raw --impure .#nixosConfigurations.axiom.config.systemd.services.autossh-reverse-ssh.serviceConfig.ExecStart
```

Result: PASS. The generated command contains:

```text
-o GlobalKnownHostsFile=/nix/store/iqbzzqvws72snfkm13z5b6x5dfz52vk6-axiom-autossh-known-hosts -o UserKnownHostsFile=/dev/null -R 127.0.0.1:2223:127.0.0.1:22 c1@8.159.128.125
```

```bash
nix eval --raw --impure .#nixosConfigurations.axiom.config.systemd.services.autossh-reverse-ssh-healthcheck.serviceConfig.ExecStart
```

Result: PASS. The runner uses `c1@"$remote_host"`, `-o GlobalKnownHostsFile=/nix/store/iqbzzqvws72snfkm13z5b6x5dfz52vk6-axiom-autossh-known-hosts`, and `-o UserKnownHostsFile=/dev/null`.

Service-specific known-hosts file readback:

```text
8.159.128.125 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE6WwypfVtdA16Au8kXoCVJgkTDlvgu98sqA0Z04Ux3l
```

Result: PASS. The generated service-specific known-hosts file contains only the refreshed `8.159.128.125` ED25519 key.

```bash
nix build .#nixosConfigurations.axiom.config.system.build.toplevel --no-link --print-out-paths --show-trace --impure
```

Result: PASS. Output path:

```text
/nix/store/mfaarn5lidppvkp5i61ckc2hacgjnrqk-nixos-system-axiom-25.11.20260630.b6018f8
```

```bash
/nix/store/bayms28s5qgq8nygm88csikkqrlcvpnj-openssh-10.3p1/bin/ssh \
  -o BatchMode=yes \
  -o ConnectTimeout=8 \
  -o GlobalKnownHostsFile=/nix/store/iqbzzqvws72snfkm13z5b6x5dfz52vk6-axiom-autossh-known-hosts \
  -o UserKnownHostsFile=/dev/null \
  c1@8.159.128.125 true
```

Result: PASS. This proves the service-specific host-key source and remote `c1` authentication work without reading stale `/home/c1/.config/ssh/known_hosts`.

```bash
kh=/nix/store/iqbzzqvws72snfkm13z5b6x5dfz52vk6-axiom-autossh-known-hosts
/nix/store/bayms28s5qgq8nygm88csikkqrlcvpnj-openssh-10.3p1/bin/ssh \
  -N \
  -o BatchMode=yes \
  -o ConnectTimeout=8 \
  -o ExitOnForwardFailure=yes \
  -o ServerAliveInterval=30 \
  -o ServerAliveCountMax=1 \
  -o GlobalKnownHostsFile="$kh" \
  -o UserKnownHostsFile=/dev/null \
  -R 127.0.0.1:2223:127.0.0.1:22 \
  c1@8.159.128.125 &
```

Then scanned remote `127.0.0.1:2223` and compared the exposed ED25519 key with `/etc/ssh/ssh_host_ed25519_key.pub`.

Result: PASS. The temporary tunnel exposed Axiom's local SSH host key, then the temporary SSH process was killed and a follow-up remote `ss` check showed no listener left on `2223`.

## Why These Checks

- The service eval proves the generated systemd unit no longer targets `root` and no longer depends on user known-hosts state.
- The healthcheck runner readback proves validation follows the same remote account and known-hosts behavior as the service.
- The service-specific known-hosts readback proves the remote server key is pinned without adding a global `/etc/ssh/ssh_known_hosts` entry.
- The toplevel build proves the full Axiom NixOS configuration still evaluates and builds.
- The temporary reverse-tunnel smoke proves the operational path can bind remote `127.0.0.1:2223` and route back to Axiom's local SSH daemon.

## Not Run

- `sudo nixos-rebuild switch --flake .#axiom --show-trace --impure`: not run because live activation requires local sudo authorization.
- `sudo systemctl restart autossh-reverse-ssh.service`: not run for the same reason.
