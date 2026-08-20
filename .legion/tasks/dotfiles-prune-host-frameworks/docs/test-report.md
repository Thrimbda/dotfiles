# Test Report: Dotfiles Prune and Host Framework Extraction

> **Result**: PASS with one unchanged baseline failure
> **Host**: `axiom`
> **Date**: 2026-08-20

## Scope Invariants

PASS:

```sh
test "$(git ls-files '.legion/tasks/*/plan.md')" = '.legion/tasks/dotfiles-prune-host-frameworks/plan.md'
test ! -e README.md
test -z "$(git diff --name-only --diff-filter=D -- .legion/wiki)"
test "$(git ls-files '.legion/wiki/**' | wc -l)" -eq 139
git diff --check
git diff --quiet -- flake.lock
git diff --quiet -- 'hosts/*/secrets/**' 'config/secrets/**'
```

This proves that only the current raw task remains, the root README is gone, the wiki layer was not pruned, and neither the lock file nor encrypted secret inventory changed.

## Syntax

PASS: `nix-instantiate --parse` succeeded for every changed Nix file under:

- `modules/services/{auth-mini-gateway,cloudflared,nginx,reverse-ssh}.nix`
- `hosts/axiom/default.nix` and `hosts/axiom/modules/*.nix`, including the rebased Qwen service
- `hosts/acorn/default.nix` and all changed/new `hosts/acorn/modules/*.nix`
- `hosts/charlie/default.nix`

## Evaluation

PASS:

```sh
env DOTFILES_HOME="$PWD" nix eval --impure --raw path:.#nixosConfigurations.axiom.config.system.build.toplevel.drvPath
env DOTFILES_HOME="$PWD" nix eval --impure --raw path:.#nixosConfigurations.acorn.config.system.build.toplevel.drvPath
env DOTFILES_HOME="$PWD" nix eval --impure --raw path:.#darwinConfigurations.charlie.system.drvPath
```

Resulting derivations:

- Axiom: `/nix/store/qv9i4w4ganvdkxs8wvb6vndv3ghsz4ys-nixos-system-axiom-26.05.7813.0dd31db7e6db.drv`
- Acorn: `/nix/store/3vbsw0d51yqnrv0p9lxscl2bp4sd064p-nixos-system-acorn-26.05.7813.0dd31db7e6db.drv`
- Charlie: `/nix/store/jmqhap297mwk2p217qx1ddinvlj0yrrw-darwin-system-26.05.c3e90c8.drv`

The Acorn candidate explicitly disables the shared Hypridle default for this server. The unchanged baseline cannot evaluate its toplevel because that default trips the desktop umbrella assertion; the candidate fixes that pre-existing inert desktop configuration and otherwise preserves the evaluated server policy.

## Behavior Snapshots

PASS: the candidate was compared with a detached `origin/master` worktree at `05ddebd8` using `diff -u` over focused `nix eval --json ... --apply` snapshots.

Axiom equal surfaces:

- autossh endpoint, command, environment and service-private known-host pin
- FRP proxies, direct-route ordering and gateway dependencies
- all three Auth Mini Gateway environments and service hardening
- cloudflared generated config and service policy
- Qwen package pin, model paths, complete argument vector, loopback endpoint, condition paths and systemd policy
- Caelestia seed/mutable settings, session path and package-data behavior
- audio, Clash, LAN firewall, user packages and system package ordering
- RustDesk runtime/provisioning unit fields and host mapping

Acorn equal surfaces:

- firewall, Nix resource limits, boot/filesystems, networkd, cloud-init, docs and SSH policy
- both Auth Mini Gateway units and the auth-mini service
- all eight DNS-01 certificates and Nginx TLS attachments
- RustDesk server options, signal/relay units, key metadata and tmpfiles rules

Charlie cloudflared config and launchd service snapshots were also equal.

The direct Axiom comparison showed one expected generated-path difference: the Caelestia session command has a different store hash because its PATH contains the Git-backed `hey` and `c1ctl` outputs. Package paths and ordering were compared separately; only those two source-derived hashes differ. Acorn restart-trigger source paths were omitted from the focused unit snapshot for the same reason. Runtime commands, package ordering, secret paths, ownership and modes are unchanged.

## Build Planning

PASS on Axiom:

```sh
env DOTFILES_HOME="$PWD" nix build --impure --dry-run path:.#nixosConfigurations.axiom.config.system.build.toplevel
```

Nix produced a valid 28-derivation plan. No build or deployment was run for Acorn.

## Full Flake Check

UNCHANGED BASELINE FAILURE:

```sh
env DOTFILES_HOME="$PWD" nix flake check --impure --no-build path:.
```

Both baseline and candidate stop at the existing app schema error:

```text
apps.x86_64-linux.install: expected a string but found a path
flake.nix:98 -> lib/nixos.nix:19
```

This is already tracked in `.legion/wiki/maintenance.md` and is outside this task.

## Not Run

- No live Axiom switch or desktop smoke; this refactor is validated through exact generated configuration comparison.
- No Acorn build, switch or deployment. Acorn safety rules were respected.
- No live Cloudflare, FRP, autossh, gateway or RustDesk probes because no deployment occurred.
