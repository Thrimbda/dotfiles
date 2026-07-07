# Walkthrough: Axiom Autossh C1ctl Check

Mode: implementation.

## Summary

This change removes the periodic Axiom autossh endpoint systemd healthcheck and moves the useful endpoint identity check into `c1ctl autossh check` as an explicit operator diagnostic.

## What Changed

- `hosts/axiom/default.nix`
  - Removes the `autossh-reverse-ssh-healthcheck` entry.
  - Injects Axiom reverse-ssh remote host/user/port/host-key values into the `c1ctl` package.
- `modules/services/healthchecks.nix`
  - Removes the unused autossh endpoint-key predicate/options.
  - Keeps HTTP and service-core healthchecks for cloudflared and Clash.
- `packages/c1ctl/default.nix`
  - Injects OpenSSH and autossh endpoint constants at build time.
- `packages/c1ctl/src/main.rs`
  - Adds `c1ctl autossh check`.
  - Creates a temporary service-specific known-hosts file with atomic `create_new`.
  - SSHes to `c1@8.159.128.125`, scans remote `127.0.0.1:2223`, and compares the exposed ED25519 key with Axiom's local SSH host key.

## Validation Evidence

- Axiom no longer generates `autossh-reverse-ssh-healthcheck.service` or timer.
- Remaining healthchecks are `cloudflared-healthcheck` and `clash-verge-healthcheck`.
- `nix build .#c1ctl --no-link --print-out-paths --show-trace --impure` passed.
- `nix build .#nixosConfigurations.axiom.config.system.build.toplevel --no-link --print-out-paths --show-trace --impure` passed.
- `c1ctl help autossh` and `c1ctl which autossh` passed.
- `c1ctl autossh check` passed against live remote `127.0.0.1:2223`.

## Operator Usage

After deployment, run the check only when needed:

```bash
c1ctl autossh check
```

If it fails, inspect/restart the owning tunnel explicitly:

```bash
systemctl status autossh-reverse-ssh.service --no-pager --lines=80
sudo systemctl restart autossh-reverse-ssh.service
```
