# Test Report: Axiom FRPC Direct Route

Date: 2026-06-29

## Summary

PASS for local declarative validation. The Axiom system evaluates and dry-run builds, and the evaluated systemd units show `frpc.service` is ordered after the direct-route service.

Runtime route installation was not performed by the agent because local `sudo -n` was unavailable.

## Commands

### Axiom Toplevel Evaluation

Command:

```sh
nix eval --raw path:/home/c1/dotfiles/.worktrees/axiom-frpc-direct-route#nixosConfigurations.axiom.config.system.build.toplevel.drvPath
```

Result: PASS.

Output:

```text
/nix/store/81l9h3dn9vp4pz3s31drkxi83naslh7z-nixos-system-axiom-25.11.20260203.e576e3c.drv
```

### Axiom Dry-run Build

Command:

```sh
nix build --dry-run path:/home/c1/dotfiles/.worktrees/axiom-frpc-direct-route#nixosConfigurations.axiom.config.system.build.toplevel
```

Result: PASS. The dry-run completed and included the expected new route service unit derivations.

### FRPC Unit Dependencies

Command:

```sh
nix eval --json path:/home/c1/dotfiles/.worktrees/axiom-frpc-direct-route#nixosConfigurations.axiom.config.systemd.services.frpc.after
nix eval --json path:/home/c1/dotfiles/.worktrees/axiom-frpc-direct-route#nixosConfigurations.axiom.config.systemd.services.frpc.wants
nix eval --json path:/home/c1/dotfiles/.worktrees/axiom-frpc-direct-route#nixosConfigurations.axiom.config.systemd.services.frpc.requires
```

Result: PASS.

- `after` includes `frpc-aliyun-acorn-direct-route.service`.
- `wants` includes `frpc-aliyun-acorn-direct-route.service`.
- `requires` includes `frpc-aliyun-acorn-direct-route.service`.

### Route Service Unit

Command:

```sh
nix eval --json path:/home/c1/dotfiles/.worktrees/axiom-frpc-direct-route#nixosConfigurations.axiom.config.systemd.services.frpc-aliyun-acorn-direct-route.before
nix eval --json path:/home/c1/dotfiles/.worktrees/axiom-frpc-direct-route#nixosConfigurations.axiom.config.systemd.services.frpc-aliyun-acorn-direct-route.after
nix eval --json path:/home/c1/dotfiles/.worktrees/axiom-frpc-direct-route#nixosConfigurations.axiom.config.systemd.services.frpc-aliyun-acorn-direct-route.wantedBy
nix eval --raw path:/home/c1/dotfiles/.worktrees/axiom-frpc-direct-route#nixosConfigurations.axiom.config.systemd.units."frpc-aliyun-acorn-direct-route.service".text
nix eval --raw path:/home/c1/dotfiles/.worktrees/axiom-frpc-direct-route#nixosConfigurations.axiom.config.systemd.units."frpc.service".text
```

Result: PASS.

- Route service has `Before=frpc.service`.
- Route service has `After=network-online.target clash-verge.service`.
- Route service is wanted by `multi-user.target`.
- `frpc.service` has `After=frpc-aliyun-acorn-direct-route.service` and `Requires=frpc-aliyun-acorn-direct-route.service`.

### Route Script Syntax

Command:

```sh
nix eval --raw path:/home/c1/dotfiles/.worktrees/axiom-frpc-direct-route#nixosConfigurations.axiom.config.systemd.services.frpc-aliyun-acorn-direct-route.script | bash -n
```

Result: PASS.

Evaluated script:

```sh
set -eu

priority=8500
target=8.159.128.125/32

ip -4 rule del priority "$priority" 2>/dev/null || true
ip -4 rule add priority "$priority" to "$target" lookup main
ip -4 route flush cache || true
```

## Skipped Runtime Validation

The following checks require deploying the new Axiom generation or local sudo access:

```sh
ip rule show | grep 8500
ip route get 8.159.128.125 uid 1000
systemctl status frpc
journalctl -u frpc -n 80 --no-pager
ssh c1@8.159.128.125 'ss -lntp "( sport = :7000 or sport = :2225 or sport = :18080 )"'
```

Expected post-deploy result:

- `ip route get 8.159.128.125 uid 1000` uses the normal LAN route from `main`, not `dev Meta table 2022`.
- `frpc.service` stays active.
- `aliyun-acorn` `frps` registers `2225` and `18080` listeners after `frpc` connects.
