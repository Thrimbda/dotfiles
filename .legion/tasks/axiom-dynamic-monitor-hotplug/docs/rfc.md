# RFC: Dynamic Axiom Monitor Hotplug

## Status

Proposed.

## Context

Axiom needs dynamic display behavior that keeps native resolution and uses the highest refresh available at that resolution. Static output rules are not enough because physical hotplug and DPMS can change the active output set, and unknown future displays should not inherit a wrong hard-coded mode. At the same time, monitor-related configuration should stay cohesive: Hyprland monitor facts, hotplug behavior, and Caelestia per-monitor overrides should be derived from one inventory.

## Decision

Extend the existing `modules.desktop.hyprland.monitors` entries as the cohesive monitor inventory instead of creating a separate display subsystem for this task.

Each monitor entry may keep current fields and add optional policy fields:

- `match`: optional identity hints such as make/model/serial/description for matching connected outputs when output names change.
- `modePolicy`: enum with `static` and `native-max-refresh`; default `static` preserves existing behavior.
- `fallbackMode`: optional static mode for startup config and for live mode discovery failure.
- `unknownPolicy`: Axiom-level default for outputs that do not match a known entry.
- `caelestia.settings`: optional attrs to seed into `~/.config/caelestia/monitors/<output>/shell.json`.

Axiom will use this inventory shape:

- OLED entry: output fallback `DP-4`, identity for Microstep MPG272UX OLED, `modePolicy = native-max-refresh`, fallback `3840x2160@240`, position `0x0`, scale `1.5`.
- Dell entry: output fallback `DP-5`, identity for Dell U2720QM, `modePolicy = native-max-refresh`, fallback `3840x2160@60`, position `2560x0`, scale `1.5`.
- Unknown displays: Axiom defaults to native-max-refresh, position `auto`, and scale `1.5`. This satisfies the 4K120 hotplug case while avoiding a static 240Hz wildcard.

Generate three artifacts from the same inventory:

1. Static `hypr/monitors.conf` for session startup and rollback-safe baseline.
2. A runtime reconcile helper installed in the session PATH and triggered from startup/reload.
3. Caelestia per-monitor seed files or pre-start merge steps for entries declaring `caelestia.settings`.
4. A lightweight Hyprland-session user service or session child that listens to the Hyprland event socket and triggers reconcile on output events.

## Runtime Algorithm

The reconcile helper should:

1. Query `hyprctl monitors all -j`.
2. Ignore disabled outputs unless they are connected and have available modes.
3. Match each connected output to a known inventory entry by identity hints first, then output name as a fallback.
4. Pick a target mode:
   - If `modePolicy = static`, use `mode` or `fallbackMode`.
   - If `modePolicy = native-max-refresh`, find the preferred mode resolution when available; otherwise find the maximum pixel-area resolution; then choose the highest refresh among modes with that resolution.
   - If live mode parsing fails, use `fallbackMode`.
5. Apply `hyprctl keyword monitor <output>,<targetMode>,<position>,<scale>` only when the live output differs materially from the target.
6. Avoid repeated retries after `hyprctl` failure in the same invocation; log and leave the output for a clean session restart.

For a 4K120 display, the policy picks `3840x2160@120` if that is the highest refresh at the native/preferred 4K resolution. It must not pick `2560x1440@240` just because 240Hz exists at a lower resolution.

## Hotplug Trigger

Hyprland exposes a session event socket under the active instance runtime directory. The implementation should generate a small watcher that:

1. Resolves `HYPRLAND_INSTANCE_SIGNATURE` and `XDG_RUNTIME_DIR` from the session environment.
2. Connects to the Hyprland event socket for the active instance.
3. Reacts to monitor/output events such as `monitoradded`, `monitorremoved`, and related output lifecycle notifications by debouncing for a short interval and then running the reconcile helper once.
4. Runs under `hyprland-session.target` with an explicit PATH and `Restart=on-failure`.

The watcher must be independently disableable through a module option or by removing the generated service, leaving static `hypr/monitors.conf` as rollback baseline.

## Caelestia Ownership

Caelestia's documented per-monitor path is `~/.config/caelestia/monitors/<screen-name>/shell.json`. The repository should not manage these as immutable Home Manager symlinks by default because the existing Axiom direction seeds mutable shell config and preserves user state.

Implementation should add a generated pre-start seed/merge script to `modules.desktop.caelestia` or to the Hyprland/Caelestia integration layer. The script creates monitor directories and writes declared per-monitor JSON only when absent or when replacing an old Nix-store symlink. If a future requirement needs strict repo ownership for a specific per-monitor setting, add a narrow merge like Axiom's existing `ensureCaelestiaSettings`, not wholesale immutable ownership.

Only per-monitor-supported Caelestia settings should be declared in monitor entries. Global-only settings such as `general.idle` should remain in global shell settings or existing mutable migration scripts.

## Alternatives

### A. Keep Manual Static Rules

This is the current shape after the emergency fix. It is simple but fails the hotplug policy: unknown 4K120 displays will not automatically get 4K120, and Caelestia monitor config remains a separate concern.

### B. New `modules.desktop.displays` Subsystem

A neutral display module would be semantically cleaner across Hyprland and Caelestia, but it requires a larger migration and compatibility layer for existing hosts already using `modules.desktop.hyprland.monitors`. This task only needs Axiom dynamic behavior, so the extra subsystem is not justified yet.

### C. Extend Existing Hyprland Monitor Inventory

This is recommended. It preserves existing consumers, adds policy only where needed, and keeps monitor facts in the surface that already owns generated Hyprland display config.

## Rollback

- Disable runtime reconcile by turning off the new hotplug/reconcile option or removing its startup/reload hook.
- Disable the hotplug watcher independently while keeping static monitor config.
- Set Axiom monitor entries back to `modePolicy = static` with explicit modes.
- Remove declared `caelestia.settings` from monitor entries; existing user-created per-monitor files can remain harmlessly unused or be manually deleted.
- If live outputs are already in a broken modeset state, perform a Hyprland session restart rather than relying on repeated runtime mode changes.

## Verification

- `nix eval --raw '.#nixosConfigurations.axiom.config.home-manager.users.c1.home.file.".config/hypr/monitors.conf".text'` shows explicit startup rules with no unsafe wildcard 240Hz line.
- Evaluate generated Caelestia monitor seed artifacts for Axiom.
- Build or evaluate the generated reconcile helper and run shell syntax/static checks where possible.
- Use captured sample `hyprctl monitors all -j` data to test native-resolution/highest-refresh selection logic if practical.
- Post-deploy live smoke: restart Hyprland, connect `DP-4` and `DP-5`, run reconcile, confirm `DP-4` is 4K240 and `DP-5` is 4K60; test a 4K120 display when available.

## Open Risks

- Hyprland/Aquamarine atomic commit failures may still require session restart.
- Identity matching must avoid applying a known monitor layout to a different physical monitor that happens to reuse the same output name.
- Caelestia per-monitor files are screen-name keyed, so output renames can leave stale per-output files behind.
