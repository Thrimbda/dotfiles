# RFC: Axiom Caelestia Never Sleep Default

## Context

Axiom currently starts Caelestia from the Hyprland startup hook and then backgrounds `axiom-caelestia-keep-awake`, which retries:

```sh
caelestia-shell ipc call idleInhibitor enable
```

That keeps Caelestia's visible Keep Awake state enabled after shell IPC is available. The user reports Axiom still sleeps, so the previous design is insufficient for the requested default. The current global Hypridle config can still run `systemctl suspend || loginctl suspend` after idle, and Caelestia's `idleInhibitor` state is not a proven login1 sleep block.

The new default must be stronger: while the Axiom graphical desktop is active, sleep should be blocked by default. The change should stay Axiom-local and avoid reintroducing the older custom power-mode toggle surface.

## Goals

- Keep Caelestia's Keep Awake / `idleInhibitor` enabled by default so the shell UI remains aligned with the requested state.
- Add an enforcement layer that blocks login1 `sleep` while the Axiom Hyprland/Caelestia session is active.
- Keep the change host-local to `axiom` and avoid changing other hosts or global Hypridle defaults.
- Preserve startup responsiveness by keeping the Caelestia IPC helper backgrounded.
- Provide static/Nix checks that prove both the UI-state helper and sleep inhibitor are wired.

## Non-Goals

- Do not add a new graphical toggle, launcher entry, or restore `axiom-sleep-mode`.
- Do not disable sleep globally across every host.
- Do not grant login1 `ignore-inhibit` or widen polkit rules.
- Do not patch upstream Caelestia QML.
- Do not run live suspend or destructive power tests from this tooling session.

## Options

### Option 1: Disable Axiom Hypridle Suspend Only

Generate an Axiom-specific `hypr/hypridle.conf` without the suspend listener, while leaving Caelestia Keep Awake as-is.

Pros:

- Prevents the known idle timeout path from calling suspend.
- Does not block explicit suspend actions.
- Could be verified by inspecting generated Hypridle text.

Cons:

- Does not satisfy "never sleep" if Caelestia, a power menu, or another session process calls login1 sleep directly.
- Reopens the older custom Hypridle override design that was superseded.
- Couples the fix to one idle daemon configuration instead of the sleep boundary.

### Option 2: Restore The Old Axiom Sleep Mode Toggle

Reintroduce `axiom-sleep-mode`, launcher entries, Hypridle wrapping, and the previous inhibitor service.

Pros:

- Known design already existed and included a sleep inhibitor.
- Offers an explicit allow-sleep mode.

Cons:

- Reintroduces duplicated state beside Caelestia's Keep Awake UI.
- Restores custom launcher and mode-management surface the later Caelestia design intentionally removed.
- Larger rollback and verification surface than the requested default-only correction.

### Option 3: Add An Axiom Caelestia Session Sleep Inhibitor

Keep the existing Caelestia `idleInhibitor enable` startup helper, and add an Axiom-local user service wanted by `hyprland-session.target` that runs:

```sh
systemd-inhibit --what=sleep --who="Axiom Caelestia" --why="Axiom Caelestia session defaults to never sleep" --mode=block tail -f /dev/null
```

The service is `PartOf=hyprland-session.target`, so it starts and stops with the graphical session. It blocks login1 sleep requests without changing global Hypridle configuration, polkit, or upstream Caelestia.

Pros:

- Satisfies the stronger never-sleep requirement at the sleep boundary.
- Keeps Caelestia's UI-state helper while adding the missing enforcement layer.
- Small Axiom-local change with straightforward static validation.
- Does not restore the old toggle/launcher state machine.

Cons:

- Manual suspend from the active graphical session is also blocked by default until the service/session is stopped.
- Runtime confirmation still requires a live Axiom session and `systemd-inhibit --list` smoke.
- The service is not a pre-login/headless policy.

## Decision

Choose Option 3.

The user's requirement is now default never sleep, and runtime feedback showed the idle-inhibitor-only design is too weak. A session-scoped `systemd-inhibit` service is the smallest change that blocks sleep requests at the correct boundary while preserving Caelestia's Keep Awake UI as the visible state.

## Scope

Production changes:

- `hosts/axiom/default.nix`: add the session sleep inhibitor service and keep the existing backgrounded Caelestia keep-awake helper.
- `hosts/axiom/README.org`: update the Keep Awake section to document the stronger never-sleep default and live checks.

Evidence changes:

- `.legion/tasks/axiom-caelestia-never-sleep-default/docs/test-report.md`
- `.legion/tasks/axiom-caelestia-never-sleep-default/docs/review-change.md`
- `.legion/tasks/axiom-caelestia-never-sleep-default/docs/report-walkthrough.md`
- `.legion/wiki/**` entries for durable current truth

## Implementation Notes

- Name the service clearly, for example `axiom-caelestia-never-sleep`.
- Start it from `hyprland-session.target`, not system boot, to preserve the graphical-session boundary.
- Use `Restart=always` or equivalent so an unexpected child exit reestablishes the inhibitor while the session is active.
- Do not make the inhibitor part of the ordered startup hook chain; it should not delay Caelestia startup.
- Keep the existing `07-caelestia-keep-awake` hook backgrounded with `nohup`.

## Verification

Static/Nix validation should prove:

- `07-caelestia-keep-awake` still uses `nohup`, backgrounds the helper, and the helper calls direct `caelestia-shell ipc call idleInhibitor enable` with the existing retry window.
- `systemd.user.services.axiom-caelestia-never-sleep` exists.
- The service is wanted by and part of `hyprland-session.target`.
- The service `ExecStart` contains `systemd-inhibit`, `--what=sleep`, `--mode=block`, and a long-running child command.
- No `axiom-sleep-mode` package or Power Mode launcher entries are reintroduced.
- `git diff --check` passes.
- `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link` passes, or any blocker is recorded.

Post-deploy live smoke should confirm:

```sh
caelestia shell idleInhibitor isEnabled
systemd-inhibit --list | grep -i 'Axiom Caelestia'
systemctl --user status axiom-caelestia-never-sleep.service
```

No live suspend test is required in this tooling session.

## Rollback

Rollback is a git revert of the Axiom host and docs changes. Operationally, before reverting, the user can stop the active-session inhibitor with:

```sh
systemctl --user stop axiom-caelestia-never-sleep.service
```

This returns sleep behavior to the previous Caelestia idle-inhibitor-only default for the current session. The service will start again on the next graphical session until the declarative change is reverted or disabled.
