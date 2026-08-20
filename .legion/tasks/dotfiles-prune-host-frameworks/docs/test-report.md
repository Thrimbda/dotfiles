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
test "$(git ls-files '.legion/wiki/**' | wc -l)" -eq 138
git diff --check
git diff --quiet -- flake.lock
git diff --quiet -- 'hosts/*/secrets/**' 'config/secrets/**'
```

This proves that only the current raw task remains, the root README is gone, the wiki layer was not pruned, and neither the lock file nor encrypted secret inventory changed.

## Syntax

PASS: `nix-instantiate --parse` succeeded for every changed Nix file under:

- `modules/services/{auth-mini-gateway,cloudflared,nginx,reverse-ssh}.nix`
- `hosts/axiom/default.nix` and `hosts/axiom/modules/*.nix`
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

- Axiom: `/nix/store/qnc3mh1mdhzqdw3c2ddhw3h1fdm44gln-nixos-system-axiom-26.05.7813.0dd31db7e6db.drv`
- Acorn: `/nix/store/sbw0cxz3hchshsakr00i56bv56qilkxl-nixos-system-acorn-26.05.7813.0dd31db7e6db.drv`
- Charlie: `/nix/store/xhi0yn5hv9klwhzs1a2kn6z2qq5pblq6-darwin-system-26.05.c3e90c8.drv`

The Acorn candidate explicitly disables the shared Hypridle default for this server. The unchanged baseline cannot evaluate its toplevel because that default trips the desktop umbrella assertion; the candidate fixes that pre-existing inert desktop configuration and otherwise preserves the evaluated server policy.

## Behavior Snapshots

PASS: baseline and candidate JSON snapshots were compared with `diff -u` using focused `nix eval --json ... --apply` expressions.

Axiom equal surfaces:

- autossh endpoint, command, environment and service-private known-host pin
- FRP proxies, direct-route ordering and gateway dependencies
- all three Auth Mini Gateway environments and service hardening
- cloudflared generated config and service policy
- Caelestia seed/mutable settings, session path and package-data behavior
- audio, Clash, LAN firewall, user packages and system packages
- RustDesk runtime/provisioning unit fields and host mapping

Acorn equal surfaces:

- firewall, Nix resource limits, boot/filesystems, networkd, cloud-init, docs and SSH policy
- both Auth Mini Gateway units and the auth-mini service
- all eight DNS-01 certificates and Nginx TLS attachments
- RustDesk server options, signal/relay units, key metadata and tmpfiles rules

The only snapshot differences were `/nix/store/<hash>-source/...` paths for age ciphertext/restart-trigger sources because baseline and candidate are distinct Git source roots. Runtime secret paths, ownership and modes are unchanged.

## Build Planning

PASS on Axiom:

```sh
env DOTFILES_HOME="$PWD" nix build --impure --dry-run path:.#nixosConfigurations.axiom.config.system.build.toplevel
```

Nix produced a valid 29-derivation plan. No build or deployment was run for Acorn.

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
