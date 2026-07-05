# Walkthrough: Axiom Autossh C1 Runtime Fix

Mode: implementation.

## Summary

This change fixes Axiom's autossh reverse SSH runtime path after the remote host was redeployed. The generated systemd service now connects to `c1@8.159.128.125`, uses a service-specific known-hosts file with the refreshed remote ED25519 host key, and avoids stale `/home/c1/.config/ssh/known_hosts` entries by setting `UserKnownHostsFile=/dev/null` for the service path.

## What Changed

- `hosts/axiom/default.nix`
  - Adds a service-specific known-hosts file for the current `8.159.128.125` ED25519 host key.
  - Sets `modules.services.reverse-ssh.remoteUser = "c1"`.
  - Sets `modules.services.reverse-ssh.globalKnownHostsFile` to that generated file and `userKnownHostsFile = "/dev/null"`.
  - Makes the autossh healthcheck inherit the service remote user and user-known-hosts setting.
- `modules/services/reverse-ssh.nix`
  - Adds optional `globalKnownHostsFile` and `userKnownHostsFile` support and passes them to the generated autossh SSH command.
- `modules/services/healthchecks.nix`
  - Adds matching optional `globalKnownHostsFile` and `userKnownHostsFile` support for autossh endpoint-key checks.

## Validation Evidence

- Generated autossh ExecStart contains `c1@8.159.128.125`, a service-specific `-o GlobalKnownHostsFile=...axiom-autossh-known-hosts`, `-o UserKnownHostsFile=/dev/null`, and the unchanged loopback forward `127.0.0.1:2223:127.0.0.1:22`.
- Generated healthcheck runner uses `c1@"$remote_host"`, the same service-specific `GlobalKnownHostsFile`, and `UserKnownHostsFile=/dev/null`.
- Generated service-specific known-hosts file contains the refreshed `8.159.128.125` ED25519 key.
- `nix build .#nixosConfigurations.axiom.config.system.build.toplevel --no-link --print-out-paths --show-trace --impure` passed.
- A service-style SSH smoke using the built known-hosts file passed for `c1@8.159.128.125`.
- A temporary reverse tunnel exposed Axiom's local SSH host key through remote `127.0.0.1:2223`, then was cleaned up.

## Deployment Handoff

The repo change is validated, but the running system still needs activation:

```bash
cd /home/c1/dotfiles
sudo nixos-rebuild switch --flake .#axiom --show-trace --impure
sudo systemctl restart autossh-reverse-ssh.service
systemctl status autossh-reverse-ssh.service --no-pager --lines=80
sudo systemctl start autossh-reverse-ssh-healthcheck.service
systemctl status autossh-reverse-ssh-healthcheck.service --no-pager --lines=80
```
