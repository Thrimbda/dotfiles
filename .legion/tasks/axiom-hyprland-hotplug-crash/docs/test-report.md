# Verification Report: Axiom Hyprland Hotplug XWayland Crash Fix

**Result:** PASS for static, package, and Axiom closure validation.
**Live-session validation:** Intentionally not run.

## Commands

| Command | Result | Evidence |
| --- | --- | --- |
| `patch --dry-run --verbose --fuzz=0 -p1 -d /nix/store/yls1h22774lz4jvx2w6mzrbi64lck59j-source < hosts/axiom/modules/hyprland-xwayland-floating-monitor-guard.patch` | PASS | One hunk applied at source line 8 with zero fuzz. |
| `nix eval --raw --option eval-cache false .#nixosConfigurations.axiom.config.programs.hyprland.package.version` | PASS | Evaluated `0.56.1`; the version assertion is active. |
| `nix build --no-link --print-out-paths --option eval-cache false .#nixosConfigurations.axiom.config.programs.hyprland.package -L` | PASS | Built patched package `/nix/store/rnxx9yav3kqkph6yq0pj3mf3k00m372i-hyprland-0.56.1`. |
| `nixos-rebuild build --flake .#axiom --show-trace -L` | PASS | Built final closure `/nix/store/8q22c48r8dhq8ifmc8hzcmbwww5mpabv-nixos-system-axiom-26.05.7813.0dd31db7e6db`. |
| Targeted `nix eval --json` checks | PASS | The selected package is the patched output, version remains `0.56.1`, XWayland is `true`, monitor hotplug is `true`, and DP-4/DP-5 both remain at scale `1.5`. |
| `git diff --cached --check` | PASS | No whitespace errors in the staged implementation. |

## Patched-Source Inspection

The built debug source overlay at `/nix/store/m9qp5z5lkb5jfh6q59bbbj26zvrk9bg6-hyprland-0.56.1-debug/src/overlay/source/src/layout/algorithm/floating/default/DefaultFloatingAlgorithm.cpp` confirms:

- The workspace monitor is locked before use.
- `WORK_AREA.pos()` is used when the monitor is absent.
- The fallback logs `Floating: no monitor for workspace while adding target; using last work area`.
- The original direct `workspace()->m_monitor->logicalBox()` access is absent from this placement path.

## Build Notes

- Early hand-written patch variants were rejected after source-overlay inspection showed that the guard hunk had not applied. They were not accepted as validation evidence.
- The final patch was reduced to one zero-fuzz hunk, rebuilt, and then inspected in the final debug overlay.
- The final closure build retried several `hyprland.cachix.org` narinfo timeouts successfully. A pre-existing static security-wrapper warning about an unused `assert_failure` function was emitted, but no build step failed and the change does not modify that wrapper.

## Deliberately Not Performed

- No `nixos-rebuild switch`, Hyprland/UWSM restart, DPMS, hotplug, or forced XWayland mapping was executed.
- Static evidence cannot prove the timing-sensitive runtime race is eliminated on physical output loss. A future explicitly authorized live test should look for the fallback warning and confirm no new Hyprland coredump or UWSM safe-mode restart.
