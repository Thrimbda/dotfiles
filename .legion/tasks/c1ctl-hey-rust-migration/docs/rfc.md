# RFC: c1ctl as the Rust successor to non-Rofi hey

> **Profile**: RFC Heavy
> **Status**: Accepted
> **Owners**: agent/user
> **Created**: 2026-06-20
> **Last Updated**: 2026-06-20

## Executive Summary

- **Problem**: `axiomctl` is too narrow, while `hey` is the broad personal control CLI but is still Janet-based.
- **Decision**: Rename the Rust CLI to `c1ctl` and start migrating the non-Rofi `hey` surface into Rust through staged, validated slices.
- **First slice**: migrate the dispatcher/introspection/path foundation into Rust: `path`, `which`, `help`, global flags, dynamic resolution for `.foo`, non-Rofi `@namespace`, `wm`, `host`, `theme`, and `exec`, while delegating high-risk mutating commands and `@rofi` to existing Janet `hey`.
- **Why now**: the current `axiomctl` name and boundary conflict with the new desired owner: a general C1 control surface.
- **Impact**: `c1ctl` becomes the canonical Rust binary; `hey` remains available for compatibility and unported commands.
- **Risks**: resolver parity, desktop bootstrap callers, high-impact Nix workflows, and global environment semantics.
- **Rollout**: one PR for rename and first Rust dispatcher slice, then follow-up PRs for command families.
- **Rollback**: revert the package rename and keep using existing Janet `hey`; no data migration is introduced in the first slice.

## 1. Background / Motivation

`hey` is both a command runner and a scripting substrate for the dotfiles. It owns rebuilds, flake updates, hooks, profile helpers, path lookup, dynamic script dispatch, and Rofi-era menu entrypoints. The first Rust CLI, `axiomctl`, only covered Axiom mode switching and a fixed reload bridge.

The new product direction is different: `c1ctl` should be the durable personal control CLI, and non-Rofi `hey` functionality should move from Janet to Rust over time. A one-shot rewrite would put critical Nix rebuild and desktop startup flows at risk, so this RFC chooses staged migration.

## 2. Goals

- Rename `packages/axiomctl` and the installed binary to `c1ctl`.
- Preserve existing Axiom mode switching under `c1ctl`.
- Start the Rust migration of `hey` with a meaningful core slice.
- Preserve compatibility for unported `hey` commands.
- Exclude Rofi internals from the Rust migration.
- Produce validation that compares or exercises the migrated semantics.

## 3. Non-goals

- Do not delete Janet `hey` in this PR.
- Do not port Rofi menus or `lib/hey/rofi*.janet`; even `@rofi` dispatch is delegated whole to Janet in this first slice.
- Do not rewrite `sync`, `gc`, `profile`, `pull`, `swap`, `vars`, or `hook` internals in the first slice.
- Do not change systemd target semantics for Axiom mode switching.
- Do not replace generated Hyprland startup calls from `hey hook startup` until hook parity exists.

## 4. Constraints

- Compatibility: existing callers of `hey` must continue working for unported commands.
- Security: Rust dynamic dispatch must execute resolved argv arrays directly, never through shell string interpolation.
- Operational: privileged mode switching must keep fixed `systemctl` argv and sudo escalation behavior.
- Rollout: use a PR-backed worktree and update Legion wiki current truth.
- Dependency: keep the first slice no-dependency unless implementation pressure proves a parser crate is worth it.

## 5. Definitions

- `c1ctl`: the new Rust CLI and package name.
- `hey`: the existing Janet command runner and compatibility surface.
- Rofi-backed: commands under `config/rofi/**` or helper libraries `lib/hey/rofi*.janet`.
- Migrated command: behavior implemented directly in Rust.
- Delegated command: `c1ctl` or compatibility wrapper passes fixed argv through to existing Janet `hey`.

## 6. Proposed Design

### 6.1 High-level Architecture

The first slice creates a Rust `c1ctl` package with two command families:

- Host-control commands inherited from `axiomctl`: `mode`, `cli`, `desktop`, `status`, and `reload`.
- Hey-foundation commands: `path`, `which`, `help`, direct-path dispatch, smart dot dispatch, non-Rofi namespace dispatch, `wm`, `host`, `theme`, and `exec`.

Non-foundation `hey` commands stay behind compatibility delegation:

- `build`, `gc`, `hook`, `info`, `ops`, `profile`, `pull`, `reload` internals, `repl`, `swap`, `sync`, `test`, and `vars` remain Janet for this PR.
- `get` and `set` remain delegated aliases into Janet `vars`.
- Rofi namespace execution remains reachable only through whole-argv delegation to Janet `hey`; Rust must not resolve or execute Rofi scripts directly.

### 6.2 Command Matrix

Immediate Rust implementation in this PR:

- `c1ctl mode [cli|desktop|status]` plus top-level aliases.
- `c1ctl reload` as a compatibility bridge to existing reload behavior.
- `c1ctl path [FLAGS] [AREA] [SEGMENTS...]` with current implementation semantics.
- `c1ctl which COMMAND [ARGS...]` using Rust resolver semantics.
- `c1ctl help COMMAND [ARGS...]` and `-h` / `--help` help extraction for resolved scripts.
- `c1ctl exec NAME [ARGS...]`.
- `c1ctl wm ...`, `c1ctl host ...`, `c1ctl theme ...`.
- `c1ctl .foo ...` smart dispatch.
- `c1ctl @namespace ...` generic namespace dispatch for non-Rofi namespaces only.

Delegated in this PR:

- `build` / `b`
- `gc`
- `hook`
- `info`
- `ops`
- `profile` / `pr`
- `pull`
- `repl`
- `swap` / `sw`
- `sync` / `s`
- `test`
- `vars`
- `get` / `set`

Explicitly excluded:

- Rofi implementation details in `config/rofi/**`, `lib/hey/rofi.janet`, and `lib/hey/rofi-blocks.janet`.
- `c1ctl @rofi ...`, `c1ctl which @rofi ...`, and `c1ctl help @rofi ...` are delegated as whole argv calls to existing Janet `hey`.

### 6.3 Resolver Semantics

Rust must preserve these behaviors for the migrated foundation:

- Search dynamic `.foo` commands in host bin, then WM bin, then repo `bin`.
- Search non-Rofi `@namespace` under `$DOTFILES_HOME/config/<namespace>/bin`.
- Treat `@rofi` as a compatibility delegation boundary: invoke existing Janet `hey` with the original operation and argv instead of resolving Rofi script paths in Rust.
- Search `wm` under `$DOTFILES_HOME/config/<wm>/bin`, with current WM detection mapping `XDG_CURRENT_DESKTOP=Hyprland` to `hypr`.
- Search `host` under `$DOTFILES_HOME/hosts/$HOST/bin`.
- Search `theme` under `$DOTFILES_HOME/modules/themes/$THEME/bin`.
- Directory descent stops at `--`, option-looking args, or missing child directory.
- Extension priority is `.janet`, `.zsh`, `.sh`, then no extension.
- Resolved scripts execute via direct argv with inherited stdio.

### 6.4 Script Execution Environment

For Rust-executed dynamic scripts, `c1ctl` must reproduce the child-process environment that existing `hey` callers depend on:

- `DOTFILES_HOME` is set to the resolved dotfiles root.
- `PATH` is set to the computed `hey` exec path, including the package sibling bin dir when available, `XDG_BIN_HOME`, generated `$XDG_DATA_HOME/hey/path` entries when present, Nix fallback paths, and the incoming process `PATH`.
- `HEYSCRIPT` is set to the resolved script path that will be executed.
- `HEYDRYRUN` is set to `1` when dry-run is active and removed otherwise.
- `HEYDEBUG` is set to the selected debug level when debug is active and removed otherwise.

For delegated Janet commands, `c1ctl` must pass the global dry-run/debug intent through argv and environment so Janet `hey` can preserve its own `HEYSCRIPT` behavior. Delegation must use direct argv execution of the injected `hey` path or equivalent Janet wrapper, not shell strings.

### 6.5 Path Semantics

Rust `path` should match current code behavior:

- `home` -> `$DOTFILES_HOME`
- `bin` -> `$DOTFILES_HOME/bin`
- `cache` -> `$XDG_CACHE_HOME/hey`
- `config` -> `$DOTFILES_HOME/config`
- `data` -> `$XDG_DATA_HOME/hey`
- `hosts` -> `$DOTFILES_HOME/hosts`
- `host` -> `$DOTFILES_HOME/hosts/$HOST`
- `lib` -> `$DOTFILES_HOME/lib`
- `modules` -> `$DOTFILES_HOME/modules`
- `runtime` -> `$XDG_RUNTIME_DIR/hey`
- `state` -> `$XDG_STATE_HOME/hey`
- `themes` -> `$DOTFILES_HOME/modules/themes`
- `theme` -> `$DOTFILES_HOME/modules/themes/$THEME`
- `wm` -> `$DOTFILES_HOME/config/<wm>`
- `wm*` -> `$XDG_CONFIG_HOME/<wm>`
- `profile` -> `/nix/var/nix/profiles/system`
- `profile*` -> `$XDG_STATE_HOME/nix/profiles/profile`
- `xdg DIR` -> `XDG_<DIR>_HOME`

Keep `-e`, `-f`, `-d`, and `-a` behavior.

### 6.6 Compatibility Strategy

This PR should not force all callers to switch immediately.

- `c1ctl` is the new canonical Rust binary.
- Janet `hey` remains installed and available.
- For unported commands, `c1ctl` delegates to existing Janet `hey` with sanitized argv and preserved `HEYDRYRUN` / `HEYDEBUG` semantics.
- For `@rofi`, `c1ctl` delegates the entire operation to existing Janet `hey`; this keeps Rofi outside the Rust implementation while preserving old callers during the transition.
- Existing scripts that call `hey` continue to work.
- A later PR may introduce a Rust-backed `hey` compatibility binary or wrapper once dispatcher parity is proven.

## 7. Alternatives Considered

### Option A: One-shot full Rust rewrite

Pros:

- Fastest path to no Janet dependency.
- Avoids maintaining compatibility delegation.

Cons:

- High risk for `sync`, `profile`, `hook`, `pull`, and desktop startup.
- Hard to validate without many destructive or host-specific operations.
- Rofi exclusion becomes tangled with dynamic dispatch replacement.

Why not:

- The task has enough risk that a single PR full rewrite would be hard to review and roll back.

### Option B: Rename only, no hey migration

Pros:

- Very low implementation risk.
- Easy to validate.

Cons:

- Does not satisfy the user's clarified goal: migrate non-Rofi `hey` from Janet into Rust.
- Leaves `c1ctl` as only a renamed `axiomctl`, which repeats the naming mistake.

Why not:

- It would not establish the Rust CLI architecture for the broader migration.

### Option C: Staged migration, foundation first

Pros:

- Starts moving the real command entrypoint semantics into Rust.
- Avoids rewriting high-impact mutating Nix workflows before parity tests exist.
- Preserves compatibility and rollback.
- Creates a clear command matrix for follow-up slices.

Cons:

- Janet remains for unported commands.
- Some behavior is duplicated temporarily.
- Exact resolver parity still requires careful tests.

Decision:

- Choose Option C.
- Give this PR a meaningful but bounded first slice: `c1ctl` rename plus Rust dispatcher/path/help/which foundation.
- Defer mutating command internals to follow-up slices.

## 8. Migration / Rollout / Rollback

### 8.1 Migration Plan

- Rename `packages/axiomctl` to `packages/c1ctl`.
- Rename Cargo package and Nix package from `axiomctl` to `c1ctl`.
- Change compile-time env names from `AXIOMCTL_*` to `C1CTL_*`.
- Update Axiom host wiring and docs.
- Implement Rust foundation commands.
- Keep existing Janet `hey` and module integration in place.
- Add task docs and wiki updates that supersede the previous `axiomctl` boundary.

No persistent data migration is required.

### 8.2 Rollout Plan

- Merge as a normal PR.
- Axiom installs `c1ctl` in system packages.
- Existing `hey` callers continue to resolve through the current Janet wrapper.
- Follow-up PRs migrate command families one at a time.

Acceptance indicators:

- `nix build .#c1ctl` succeeds.
- `c1ctl --help`, `c1ctl mode --help`, and migrated help/which/path commands succeed.
- Axiom host eval includes `c1ctl` and no longer references `axiomctl` as the installed package.
- Compatibility delegation reaches current Janet `hey` for at least one delegated command without changing behavior.

### 8.3 Rollback Plan

Rollback conditions:

- `c1ctl` build fails.
- Axiom eval fails.
- Resolver parity breaks existing dynamic dispatch.
- Delegation to Janet `hey` fails for unported commands.

Rollback steps:

- Revert the PR.
- Axiom returns to the previous `axiomctl` package and existing Janet `hey` behavior.
- No data consistency repair is needed because first slice has no new persistent store.

## 9. Observability

- CLI errors should be explicit and command-prefixed with `c1ctl:`.
- Delegation failures should include the delegated program path and exit status.
- `which` remains the primary debug playbook for resolver issues.
- `-?`, `-??`, `-???`, and `HEYDEBUG` should remain available for delegated command visibility.

## 10. Security & Privacy

- Do not execute shell strings. Always invoke `Command` with argv arrays.
- Keep privileged mode switching on fixed `systemctl` argv.
- Do not widen sudo behavior beyond existing mode commands.
- Do not read or expose secrets.
- Do not port Rofi menus, `@rofi` resolution, or clipboard/history UI behavior in this task.
- Preserve user-controlled script execution only as unprivileged compatibility dispatch.

## 11. Testing Strategy

Unit or command-level tests:

- Rust parser and path resolver tests if practical inside the crate.
- Golden command comparisons against current Janet for safe commands: `path`, `which`, help extraction, dynamic resolution.

Integration validation:

- `rustfmt --check` for the Rust source.
- `nix build --impure --no-link --print-out-paths .#c1ctl`.
- Run built `c1ctl --help` and `c1ctl mode --help`.
- Run built `c1ctl path home`, `c1ctl path xdg data`, `c1ctl which .backup`, and a non-executing `which @rofi ...` compatibility check.
- Run a delegated command in a safe mode, such as `c1ctl which sync` or `c1ctl help sync`, without executing rebuilds.
- Run at least one Rust-executed dynamic script env check that proves `DOTFILES_HOME`, `PATH`, `HEYSCRIPT`, `HEYDRYRUN`, and `HEYDEBUG` are set as specified.
- Run at least one delegated Janet command env/global-option check that proves dry-run/debug intent is preserved.
- Eval Axiom host package list for `c1ctl` and stale `axiomctl` removal.
- `git diff --check`.

Manual validation after deployment:

- `c1ctl status`.
- `c1ctl mode cli` from SSH.
- `c1ctl mode desktop` from local/graphical recovery path.
- `c1ctl reload` in a graphical session.

## 12. Milestones

### Milestone 1: Rename and packaging

Scope:

- `packages/axiomctl` -> `packages/c1ctl`.
- Cargo/Nix/env/doc naming.
- Axiom host wiring.

Acceptance:

- `.#c1ctl` builds.
- Axiom eval installs `c1ctl`.
- `axiomctl` is not presented as the current binary.

Rollback impact:

- Revert package rename and host wiring.

### Milestone 2: Rust foundation commands

Scope:

- `path`, `which`, `help`, global flags, and dynamic resolver semantics.
- Generic script execution compatibility.
- Delegation to Janet for unported commands.

Acceptance:

- Safe parity checks pass for resolver/path/help/which.
- Rofi internals remain untouched.
- `@rofi` is delegated to Janet and not resolved or executed directly by Rust.
- Rust-executed dynamic scripts receive the specified child-process environment.
- Delegated commands remain reachable through current Janet `hey`.

Rollback impact:

- Revert `c1ctl` implementation; existing `hey` remains untouched.

### Milestone 3: Documentation and current truth

Scope:

- Axiom README.
- Legion task docs.
- Legion wiki decisions/patterns/maintenance/task summary.

Acceptance:

- Docs describe `c1ctl` as canonical.
- Docs no longer claim broad workflows must stay in `hey` forever.
- Docs still state Rofi is out of scope for this migration.

Rollback impact:

- Revert docs with code rollback.

## 13. Open Questions

- None blocking for the first slice.

Follow-up questions:

- Should a later PR replace the `hey` binary with a Rust `c1ctl` compatibility wrapper?
- Which command family should be ported next after dispatcher/path foundation: hooks, vars, or Nix rebuild/profile helpers?

## 14. Implementation Notes

Expected files:

- `packages/c1ctl/**`
- `hosts/axiom/default.nix`
- `hosts/axiom/README.org`
- `.legion/tasks/c1ctl-hey-rust-migration/**`
- `.legion/wiki/**`

Suggested order:

- Rename package and env names.
- Refactor Rust parser into command groups.
- Add path model and resolver.
- Add `help`/`which`/`exec` operations.
- Add delegation for unported commands.
- Update docs and validation evidence.

## 15. References

- Plan: `.legion/tasks/c1ctl-hey-rust-migration/plan.md`
- Research: `.legion/tasks/c1ctl-hey-rust-migration/docs/research.md`
- Current Rust CLI: `packages/c1ctl/src/main.rs`
- Janet entrypoint: `bin/hey`
- Janet resolver: `lib/hey/init.janet`
- Janet path model: `lib/hey/lib.janet`
- Hey module: `modules/hey.nix`
