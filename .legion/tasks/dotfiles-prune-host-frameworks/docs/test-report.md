# Test Report: Dotfiles Prune and Host Framework Extraction

> **Result**: PASS with one unchanged baseline failure
> **Host**: `axiom`
> **Date**: 2026-08-20

## Scope Invariants

PASS:

```sh
base=origin/master
test "$(git ls-files '.legion/tasks/*/plan.md')" = \
  '.legion/tasks/dotfiles-prune-host-frameworks/plan.md'
test ! -e README.md
test -z "$(git diff --name-only --diff-filter=D "$base" -- .legion/wiki)"
test "$(git ls-files '.legion/wiki/**' | wc -l)" -ge \
  "$(git ls-tree -r --name-only "$base" .legion/wiki | wc -l)"
git diff --check "$base"
git diff --quiet "$base" -- flake.lock
git diff --quiet "$base" -- 'hosts/*/secrets/**' 'config/secrets/**'
```

This proves that only the current task remains, the root README is gone, all 142 baseline wiki files were retained, and neither the lock file nor encrypted secret inventory changed. The closing writeback adds this task's wiki summary as file 143.

## Syntax

PASS: `nix-instantiate --parse` succeeded for all 22 changed Nix files under:

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

All three commands returned concrete derivation paths. They are intentionally not copied here: this repository packages its Git source, so writing a path into this report changes the next source and derivation hashes recursively.

The Acorn candidate explicitly disables the shared Hypridle default for this server. The unchanged baseline cannot evaluate its toplevel because that default trips the desktop umbrella assertion; the candidate fixes that pre-existing inert desktop configuration and otherwise preserves the evaluated server policy.

## Behavior Snapshots

PASS: the candidate was compared with a detached `origin/master` worktree at `07816e00` using `diff -u` over focused `nix eval --json ... --apply` snapshots. Git-source store hashes were normalized, package lists were compared by name, and raw credential-source paths were omitted.

Axiom equal surfaces:

- autossh endpoint, command, environment and service-private known-host pin
- FRP proxies, direct-route ordering and gateway dependencies
- all three Auth Mini Gateway environments and service hardening
- cloudflared generated config and service policy
- Qwen package pin, Q4/Q6 paths, mutable selection link, bounded controller, sudo-wrapper path, 128K argument vector, loopback endpoint, preflight and systemd policy
- Caelestia seed/mutable settings, session path and package-data behavior
- audio, Clash, LAN firewall, user packages and system package ordering
- RustDesk runtime/provisioning unit fields and host mapping

Acorn equal surfaces:

- firewall, Nix resource limits, boot/filesystems, networkd, cloud-init, docs and SSH policy
- both Auth Mini Gateway units and the auth-mini service
- all eight DNS-01 certificates and Nginx TLS attachments
- RustDesk server options, signal/relay units, key metadata and tmpfiles rules

Charlie cloudflared config and launchd service snapshots were also equal.

A separate Acorn desktop-option snapshot showed the one intentional delta: `modules.desktop.hyprland.hypridle.enable` changes from `true` to `false`, while Hyprland remains disabled and no Hypridle unit exists in either configuration. This removes the pre-existing desktop assertion without changing runtime service behavior. All normalized service snapshots were otherwise empty diffs.

## Build Planning

PASS on Axiom:

```sh
env DOTFILES_HOME="$PWD" nix build --impure --dry-run path:.#nixosConfigurations.axiom.config.system.build.toplevel
```

Both baseline and candidate produced valid 28-derivation plans. No build or deployment was run for Acorn.

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
