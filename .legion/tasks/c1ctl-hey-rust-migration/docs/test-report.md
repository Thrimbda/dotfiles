# Test Report: C1ctl Hey Rust Migration

## Summary

PASS

The implemented first slice builds, preserves Axiom package wiring, exercises the new Rust foundation commands, delegates `@rofi` and unported commands to Janet `hey`, and keeps current code free of stale `axiomctl` package references.

## Commands

### Rust Format

Command:

```sh
nix shell nixpkgs#rustfmt -c rustfmt --check packages/c1ctl/src/main.rs
```

Result: PASS

Notes:

- Nix emitted the known non-fatal eval-cache warning: `attempt to write a readonly database`.

### Package Build

Command:

```sh
nix build --impure --no-link --print-out-paths .#c1ctl
```

Result: PASS

Output:

```text
/nix/store/5j3zcy150m24vrpkpzbkinizmqsysgls-c1ctl-0.1.0
```

### CLI Behavior And Env Contract

Command:

```sh
C1CTL=$(nix build --impure --no-link --print-out-paths .#c1ctl) && \
env -u DOTFILES_HOME "$C1CTL/bin/c1ctl" --help >/dev/null && \
env -u DOTFILES_HOME "$C1CTL/bin/c1ctl" mode --help >/dev/null && \
export DOTFILES_HOME="$PWD" \
  XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}" \
  XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}" \
  XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}" \
  XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}" \
  XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}" \
  XDG_CURRENT_DESKTOP=Hyprland \
  HOST=axiom \
  THEME=default \
  JANET_PATH="$PWD/lib:/home/c1/.local/share/janet/jpm_tree/lib" \
  JANET_TREE="/home/c1/.local/share/janet/jpm_tree" && \
"$C1CTL/bin/c1ctl" --help >/dev/null && \
"$C1CTL/bin/c1ctl" mode --help >/dev/null && \
"$C1CTL/bin/c1ctl" path home >/dev/null && \
"$C1CTL/bin/c1ctl" path xdg data >/dev/null && \
"$C1CTL/bin/c1ctl" which .backup >/dev/null && \
"$C1CTL/bin/c1ctl" which path >/dev/null && \
"$C1CTL/bin/c1ctl" help path >/dev/null && \
"$C1CTL/bin/c1ctl" which @rofi wifimenu >/dev/null && \
"$C1CTL/bin/c1ctl" help sync >/dev/null && \
SCRIPT_PATH=$("$C1CTL/bin/c1ctl" which exec env) && \
OUT=$("$C1CTL/bin/c1ctl" -! '-??' exec env) && \
[[ "$OUT" == *"DOTFILES_HOME=$PWD"* ]] && \
[[ "$OUT" == *"PATH="*"$PWD/bin"* ]] && \
[[ "$OUT" == *"HEYSCRIPT=$SCRIPT_PATH"* ]] && \
[[ "$OUT" == *"HEYDRYRUN=1"* ]] && \
[[ "$OUT" == *"HEYDEBUG=2"* ]] && \
DELEGATED=$("$C1CTL/bin/c1ctl" -! '-??' which @rofi wifimenu 2>&1 >/dev/null) && \
[[ "$DELEGATED" == *"Enabled debug mode"* ]] && \
[[ "$DELEGATED" == *"Enabled dry run mode"* ]] && \
! "$C1CTL/bin/c1ctl" which @@rofi wifimenu >/dev/null 2>&1 && \
! "$C1CTL/bin/c1ctl" which @rofi/bin/.. wifimenu >/dev/null 2>&1 && \
! "$C1CTL/bin/c1ctl" which @hypr ../../rofi/bin/wifimenu >/dev/null 2>&1 && \
! "$C1CTL/bin/c1ctl" which wm ../rofi/bin/wifimenu >/dev/null 2>&1 && \
! "$C1CTL/bin/c1ctl" which .../config/rofi/bin/wifimenu >/dev/null 2>&1
```

Result: PASS

Why this proves the change:

- `c1ctl --help` and `c1ctl mode --help` work without `DOTFILES_HOME`, so host-control help does not depend on dotfiles context.
- `path`, `which`, and `help` exercise Rust foundation commands.
- `which @rofi wifimenu` proves `@rofi` remains reachable through Janet delegation without Rust resolving Rofi scripts directly.
- `help sync` proves an unported mutating command can be delegated safely without executing it.
- `c1ctl -! -?? exec env` proves Rust-executed dynamic commands receive `DOTFILES_HOME`, computed `PATH`, exact resolved `HEYSCRIPT`, `HEYDRYRUN=1`, and `HEYDEBUG=2`.
- `c1ctl -! -?? which @rofi wifimenu` proves dry-run/debug intent reaches delegated Janet `hey`.
- Negative checks prove `@@rofi`, `@rofi/bin/..`, non-Rofi namespace traversal, `wm` traversal, and dot-command traversal cannot bypass the Rofi boundary.

### Axiom Package Wiring

Command:

```sh
nix eval --impure --json --expr 'let c = (builtins.getFlake (toString ./.)).nixosConfigurations.axiom.config; names = map (p: p.name or "") c.environment.systemPackages; hasC1ctl = builtins.any (n: builtins.match "c1ctl-.*" n != null) names; hasAxiomctl = builtins.any (n: builtins.match "axiomctl-.*" n != null) names; in { inherit hasC1ctl hasAxiomctl; }'
```

Result: PASS

Output:

```json
{"hasAxiomctl":false,"hasC1ctl":true}
```

### Axiom Toplevel Dry-Run

Command:

```sh
nix build --impure --dry-run .#nixosConfigurations.axiom.config.system.build.toplevel
```

Result: PASS

Notes:

- Nix emitted transient Cachix timeout retry warnings, then completed dry-run and listed the derivations that would be built.

### Current Code And Wiki Truth Stale References

Command:

```sh
rg 'axiomctl|AXIOMCTL|packages/axiomctl' hosts packages modules flake.nix .legion/wiki/decisions.md .legion/wiki/patterns.md .legion/wiki/maintenance.md
```

Result: PASS

Output: no matches in current code or current-truth wiki pages. Historical task pages may still mention `axiomctl` as superseded context.

### Diff Whitespace

Command:

```sh
git diff --check
```

Result: PASS

## Skipped

- Did not run `c1ctl mode cli`, `c1ctl mode desktop`, or `c1ctl reload`; these intentionally affect active system/session state and belong to post-deploy smoke validation.
- Did not execute delegated mutating commands such as `sync`, `gc`, `pull`, `profile`, or `swap`; this slice validates safe delegation and help/which surfaces only.
