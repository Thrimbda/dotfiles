# Research: Axiom Hyprland Hotplug XWayland Crash

## Evidence

- Four retained Hyprland 0.56.1 incidents share the same XWayland surface-map to floating-layout stack. The latest report is `/home/c1/.cache/hyprland/hyprlandCrashReport3545154.txt`, with the primary frames at lines 68-155.
- In two complete compositor logs, DP-4 and DP-5 disconnect before the failing map path. The latest sequence is in `/run/user/1000/hypr/5c9377c15f85c50648f35ca5a213754f95b93ca0_1787196867_977409074/hyprland.log` at lines 1691-1763.
- The crash report records the original SIGSEGV. Hyprland's crash handler subsequently aborts, which accounts for systemd-coredump recording SIGABRT.
- Portal, RustDesk, EasyEffects, Fcitx, and Zen fail only after UWSM observes the compositor exit. They are not evidence of the initiating crash.

## Current Package Path

- Axiom selects `pkgs.unstable.hyprland` through `modules/desktop/hyprland.nix` at lines 457-463.
- The evaluated package is `hyprland-0.56.1`; its Nixpkgs definition fetches upstream tag `v0.56.1` in `pkgs/by-name/hy/hyprland/package.nix` at lines 86-111.
- The host can override `programs.hyprland.package` without changing the portal package, flake inputs, monitor definitions, XWayland settings, or the shared package set.

## Source Finding

- `CSpace::recheckWorkArea` already returns when its workspace has no monitor, preserving the previous work area. See Hyprland `src/layout/space/Space.cpp` at lines 77-107.
- `CSpace::add` still unconditionally calls `CAlgorithm::addTarget`, which calls `CDefaultFloatingAlgorithm::newTarget` for floating targets. See `Space.cpp` lines 39-48 and `Algorithm.cpp` lines 30-40.
- `CDefaultFloatingAlgorithm::newTarget` unconditionally reads `workspace()->m_monitor->logicalBox().pos()` before it handles desired geometry. See `src/layout/algorithm/floating/default/DefaultFloatingAlgorithm.cpp` lines 19-23.
- A monitor-less workspace can exist while all outputs are disconnected. The monitor-disconnect path has no backup monitor in that state, and workspace migration later restores a monitor association.

## Upstream Status

- No released or mainline post-v0.56.1 change guards this dereference. v0.56.2 does not contain a relevant map/floating/missing-monitor fix.
- Post-v0.56.1 floating placement changes such as `b3aa455` occur after the dereference and do not provide a safe backport for this incident.

## Residual Unknowns

- The triggering X11 client is not retained in the available artifacts.
- DP connector loss is an immediate timing correlate, but the artifacts cannot prove whether it was physical, DPMS, cable/port behavior, or another display-path transition.
- A static build can prove patch application and compilation, but not eliminate the need for a future explicitly authorized hotplug/DPMS runtime smoke.
