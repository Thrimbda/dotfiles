# Research Notes: C1ctl Hey Rust Migration

## 1. Problem Restatement

Rename the current Rust `axiomctl` package to `c1ctl` and start moving the non-Rofi `hey` command surface from Janet into Rust. The first slice must be useful enough to establish `c1ctl` as the new control surface, but safe enough that high-impact Nix workflows can remain delegated until parity is proven.

Impact areas:

- Rust package under `packages/c1ctl` after this implementation.
- Axiom host package wiring and README.
- Janet `hey` entrypoint and command modules under `bin/hey` and `bin/hey.d`.
- Janet support libraries under `lib/hey`.
- Nix module integration in `modules/hey.nix`.
- Scripts and configs that call `hey path`, `hey hook`, `hey reload`, `hey .foo`, and `hey @rofi`.

## 2. Relevant Code / Entry Points

- `packages/c1ctl/src/main.rs` - current Rust CLI. It handles Axiom mode switching, status, the fixed `reload` bridge, and the first Rust `hey` foundation slice.
- `packages/c1ctl/default.nix` - Rust package named `c1ctl`, with injected `C1CTL_SYSTEMCTL` and `C1CTL_HEY`.
- `hosts/axiom/default.nix` - calls `../../packages/c1ctl` and installs the resulting package.
- `bin/hey` - Janet top-level dispatcher. It maps static commands such as `sync`, `gc`, `profile`, `pull`, `reload`, `path`, `vars`, and dynamic patterns such as `.foo`, `@namespace`, `wm`, `host`, `theme`, and `exec`.
- `lib/hey/init.janet` - resolver, global options, help extraction, `which`, and dispatch engine.
- `lib/hey/lib.janet` - path model, XDG paths, host/theme/wm metadata, executable search path, and logging helpers.
- `modules/hey.nix` - installs the `hey` wrapper, exports Janet environment variables, generates `hey/info.json`, generates hook scripts, and deploys compiled Janet `hey` during user activation.

## 3. Existing Hey Command Surface

Top-level commands implemented in `bin/hey`:

- `build`, alias `b` - build VM/ISO targets or rebuild/deploy `hey`.
- `get`, `set` - aliases into `vars get` and `vars set`.
- `gc` - Nix garbage collection for user/system/all profiles.
- `hook` - execute configured hook scripts from generated, host, and WM hook dirs.
- `host` - dispatch into `$DOTFILES_HOME/hosts/$HOST/bin`.
- `info` - emit flake info, IP facts, or `nix-prefetch-git` metadata.
- `ops` - placeholder command; currently not implemented.
- `path` - print known dotfiles/XDG paths.
- `profile`, alias `pr` - inspect/remove/diff Nix generations and profile paths.
- `pull` - update flake inputs, including input selection and overrides.
- `reload`, alias `re` - run reload hooks and user feedback.
- `repl` - open Janet, Nix, or nix-develop REPL.
- `swap`, alias `sw` - replace Nix store symlinks with editable copies and restore them.
- `sync`, alias `s` - run NixOS or nix-darwin rebuild flows.
- `test` - run `judge $DOTFILES_HOME/test/hey`.
- `theme` - dispatch into `$DOTFILES_HOME/modules/themes/$THEME/bin`.
- `vars` - file-backed temporary and global variables.
- `wm` - dispatch into `$DOTFILES_HOME/config/$WM/bin`.
- `exec` - resolve and execute a binary from the computed `hey` path.
- Direct path dispatch for `./*` and `/*`.
- Smart command dispatch for `.foo`, searching host bin, then WM bin, then repo `bin`.
- Namespace dispatch for `@namespace`, searching `$DOTFILES_HOME/config/<namespace>/bin`.
- Global `help`/`h` and `which` operations.

Command modules under `bin/hey.d`:

- `build.janet` - `iso`, `vm`, and `hey` build helpers.
- `gc.janet` - Nix profile garbage collection and `nix-store --optimise`.
- `hook.janet` - hook discovery, de-duplication, locking, and execution.
- `info.janet` - flake info, local/WAN IP, and GitHub prefetch helper.
- `ops.janet` - placeholder remote-host ops command.
- `path.janet` - path lookup and existence filters.
- `profile.janet` - generation listing/removal/diff and profile path output.
- `pull.janet` - flake input update/override flow.
- `reload.janet` - `hook reload -f -v` plus feedback.
- `repl.janet` - Janet/Nix/nix-develop REPL entrypoints.
- `swap.janet` - store symlink swap/unswap/list/reset.
- `sync.janet` - NixOS/nix-darwin rebuild path.
- `vars.janet` - file-backed variable get/set/list.

## 4. Dynamic Dispatch Semantics

Current resolver behavior lives in `lib/hey/init.janet`:

- Directory descent walks command words until `--`, an option-like argument, or no matching `*.d` directory remains.
- Script extension priority is `.janet`, `.zsh`, `.sh`, then no extension.
- `which` prints the resolved target path and forwarded args without executing.
- `help` reads contiguous header comments after a shebang from the resolved script.
- Global options are removed before command-local parsing.
- Child process environment gets `HEYSCRIPT`, `HEYDRYRUN`, `HEYDEBUG`, `PATH`, and `DOTFILES_HOME`.
- `-!` sets dry-run state but only commands using `do?`, `hey!`, or zsh `hey.do` honor it.
- `-?`, `-??`, and `-???` set debug levels; `HEYDEBUG` also participates.

## 5. Rofi Boundary

Rofi-backed functionality should not be ported in this task.

Exclude:

- `config/rofi/**`.
- `lib/hey/rofi.janet`.
- `lib/hey/rofi-blocks.janet`.
- `modules/desktop/apps/rofi.nix` command bodies such as `hey @rofi wifimenu`.
- `packages/rofi-blocks/**`.

The Rust dispatcher may preserve generic non-Rofi `@namespace` execution compatibility. `@rofi` remains outside the Rust implementation and should be delegated whole to existing Janet `hey` if compatibility is needed.

## 6. Existing Decisions To Supersede

`.legion/wiki/decisions.md` currently states that `axiomctl` should stay a narrow Rust host-control CLI and broad workflows should remain owned by `hey`. The user has explicitly superseded that direction: the durable binary should be `c1ctl`, and non-Rofi `hey` functionality should migrate from Janet into Rust.

The parts still worth preserving are:

- fixed privileged `systemctl` argv for mode switching;
- Rofi exclusion;
- staged migration rather than deleting Janet before parity.

## 7. Risks & Pitfalls

- Dynamic dispatch is the compatibility contract for many scripts. Getting `.d` descent, extension order, `--`, or option boundary behavior wrong can break existing callers.
- The current `hey path` documentation says `config` maps to XDG config, but implementation maps it to `$DOTFILES_HOME/config`. Implementation should preserve code behavior, not stale docs.
- `sync`, `gc`, `profile`, `pull`, and `swap` are high-impact. A first slice should delegate them unless it also includes serious parity tests and rollback evidence.
- Global dry-run/debug behavior is inherited by child scripts through environment variables. Delegation must preserve those env vars.
- `hey` is used in generated Hyprland config and hooks. Replacing the `hey` binary too early could break desktop bootstrap.
- Rofi commands should remain reachable through compatibility dispatch where existing configs still call `hey @rofi ...`, but Rofi internals remain out of scope.

## 8. Unknowns

- Whether a later slice should replace the `hey` binary with a Rust wrapper or keep `hey` as a long-lived compatibility alias to `c1ctl`.
- How much exact text parity is required for `help` output across all script types.
- Whether `vars` should remain file-compatible with Janet's temp/global stores or move to a new schema in a later task.

## 9. References

- Task plan: `.legion/tasks/c1ctl-hey-rust-migration/plan.md`
- Current Rust CLI: `packages/c1ctl/src/main.rs`
- Janet entrypoint: `bin/hey`
- Janet dispatch library: `lib/hey/init.janet`
- Janet path library: `lib/hey/lib.janet`
- Hey module integration: `modules/hey.nix`
- Axiom host package wiring: `hosts/axiom/default.nix`
