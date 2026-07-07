# Test Report: Axiom Autossh C1ctl Check

## Summary

PASS. The Axiom autossh endpoint systemd healthcheck service/timer is no longer generated, remaining healthchecks are intact, `c1ctl` builds, and `c1ctl autossh check` successfully verified the live remote endpoint.

## Commands

```bash
nix eval --impure --json .#nixosConfigurations.axiom.config.systemd.services --apply 'services: builtins.hasAttr "autossh-reverse-ssh-healthcheck" services'
```

Result: PASS, output `false`.

```bash
nix eval --impure --json .#nixosConfigurations.axiom.config.systemd.timers --apply 'timers: builtins.hasAttr "autossh-reverse-ssh-healthcheck" timers'
```

Result: PASS, output `false`.

```bash
nix eval --impure --json .#nixosConfigurations.axiom.config.modules.services.healthchecks.checks --apply 'checks: builtins.attrNames checks'
```

Result: PASS, output:

```json
["clash-verge-healthcheck","cloudflared-healthcheck"]
```

```bash
nix eval --impure --json .#nixosConfigurations.axiom.config.systemd.timers --apply 'timers: builtins.filter (name: builtins.match ".*healthcheck.*" name != null) (builtins.attrNames timers)'
```

Result: PASS, output:

```json
["clash-verge-healthcheck","cloudflared-healthcheck"]
```

```bash
nix build .#c1ctl --no-link --print-out-paths --show-trace --impure
```

Result: PASS, output:

```text
/nix/store/a6xfcxm6g2jlri2v20c67vyggx3m8rbj-c1ctl-0.1.0
```

```bash
nix build .#nixosConfigurations.axiom.config.system.build.toplevel --no-link --print-out-paths --show-trace --impure
```

Result: PASS, output:

```text
/nix/store/22nra5jr2cb2p138vqg6n1nhkz24vx1b-nixos-system-axiom-25.11.20260630.b6018f8
```

```bash
/nix/store/22nra5jr2cb2p138vqg6n1nhkz24vx1b-nixos-system-axiom-25.11.20260630.b6018f8/sw/bin/c1ctl help autossh
```

Result: PASS. Output documents `c1ctl autossh check`.

```bash
/nix/store/22nra5jr2cb2p138vqg6n1nhkz24vx1b-nixos-system-axiom-25.11.20260630.b6018f8/sw/bin/c1ctl which autossh
```

Result: PASS, output `c1ctl autossh`.

```bash
XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp} \
  /nix/store/22nra5jr2cb2p138vqg6n1nhkz24vx1b-nixos-system-axiom-25.11.20260630.b6018f8/sw/bin/c1ctl autossh check
```

Result: PASS. Output:

```text
autossh endpoint ok: 8.159.128.125:127.0.0.1:2223 exposes Axiom local SSH host key
```

Additional remote listener evidence:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=8 c1@8.159.128.125 "ss -H -ltnp '( sport = :2223 )' 2>/dev/null || true"
```

Result: PASS, output shows `LISTEN` on `127.0.0.1:2223`.

## Notes

- A first attempt to create a temporary `-R 127.0.0.1:2223` tunnel reported that the remote port was already in use. The subsequent clean `c1ctl autossh check` passed against the existing live listener.
- The new command is an explicit operator diagnostic. It does not restart autossh or create background automation.
