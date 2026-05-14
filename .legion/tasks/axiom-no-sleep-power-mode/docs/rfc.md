# RFC: Axiom No-Sleep Power Mode

## Status

Draft for review.

## Context

Axiom currently inherits the repository `config/hypr/hypridle.conf`, which locks after 5 minutes, turns DPMS off after 10 minutes, and runs `systemctl suspend || loginctl suspend` after 15 minutes. That default is not acceptable for the Axiom workstation because unattended suspend interrupts remote access and long-running local work. The desired behavior is not to remove sleep support entirely: Axiom should default to no-sleep, and the desktop should expose an explicit switch back to allow-sleep mode.

## Goals

- Axiom defaults to no-sleep behavior for the Hyprland/Caelestia desktop.
- Automatic idle suspend is skipped while no-sleep mode is active.
- Direct sleep requests are also blocked while no-sleep mode is active, so the workstation does not sleep accidentally through another desktop power surface.
- The user can switch modes from the desktop without editing config files.
- Other hosts keep their current Hypridle behavior.

## Non-Goals

- Do not redesign Caelestia quick controls or add a new graphical settings panel.
- Do not remove NixOS suspend/hibernate capability globally.
- Do not change CPU/GPU power tuning, power profiles, brightness, or fan behavior.
- Do not run disruptive live suspend tests in this session.

## Options

### Option A: Remove The Suspend Listener Globally

Delete the suspend listener from `config/hypr/hypridle.conf`.

Pros:
- Smallest code change.
- Prevents Hypridle auto-suspend everywhere.

Cons:
- Violates Axiom-only scope.
- Provides no desktop switch back to allow-sleep.
- Silently changes behavior for other hosts.

Verdict: Reject.

### Option B: Axiom-Only Hypridle Override With Scripted Maybe-Suspend

Override Axiom's generated `hypr/hypridle.conf` so the suspend listener calls an Axiom-local command such as `axiom-sleep-mode maybe-suspend`. The command checks user-local mode state and only calls `systemctl suspend || loginctl suspend` when mode is `allow-sleep`.

Pros:
- Scoped to Axiom.
- Avoids repeated failed suspend calls while no-sleep mode is active.
- Keeps the existing lock and DPMS behavior.
- Easy to verify by inspecting generated config.

Cons:
- Only covers the Hypridle auto-suspend path.
- Direct sleep requests from another desktop surface could still suspend the machine.

Verdict: Useful but insufficient alone.

### Option C: Boot Specialisation / NixOS Power Profile

Create a NixOS boot specialisation or alternate host configuration that masks suspend behavior.

Pros:
- Declarative and easy to reason about at boot.
- Strong isolation from normal mode.

Cons:
- Does not satisfy desktop switching without rebooting.
- Makes a runtime desktop preference into a boot-time operating mode.
- Likely over-scoped for the request.

Verdict: Reject.

### Option D: Axiom Script + Hypridle Override + User Sleep Inhibitor

Install an Axiom-local `axiom-sleep-mode` command and desktop launcher entries. The command owns a small mode state under `$XDG_STATE_HOME/axiom-power-mode/sleep-mode`, defaults to `no-sleep` when no state exists, and supports `no-sleep`, `allow-sleep`, `toggle`, `status`, `apply`, and `maybe-suspend` verbs.

Add two Axiom user services:
- `axiom-no-sleep-inhibit.service`: runs `systemd-inhibit --what=sleep --mode=block ... sleep infinity` while no-sleep mode is active.
- `axiom-sleep-mode-apply.service`: starts with the Hyprland session and applies the current mode by starting or stopping the inhibitor.

Override Axiom's `hypr/hypridle.conf` so the suspend listener calls `axiom-sleep-mode maybe-suspend`. Add desktop launcher entries for no-sleep, allow-sleep, and toggle mode.

Pros:
- Scoped to Axiom.
- Default no-sleep is effective for both Hypridle auto-suspend and accidental direct sleep requests.
- The allow-sleep mode preserves the existing lock/DPMS/suspend intent when explicitly selected.
- Does not widen polkit permissions; it only adds a user-owned inhibitor and user command.
- Provides a desktop-accessible switch without a full Caelestia UI redesign.

Cons:
- Slightly more moving parts than a static Hypridle edit.
- Static validation can prove config shape but not long-idle behavior without a live session.
- If the user selects allow-sleep, that explicit state can persist until changed back.

Verdict: Select.

## Decision

Implement Option D.

The selected design keeps the global Hyprland import intact and applies the no-sleep policy only in `hosts/axiom/default.nix`. Axiom gets a small fixed-command power-mode surface rather than a new graphical panel. The command controls both the Hypridle suspend decision and a systemd sleep inhibitor so the default mode means more than simply hiding one idle timeout.

The default mode is `no-sleep` when no user state file exists. If the user deliberately switches to `allow-sleep`, that state may persist until the user switches back; this is acceptable because it is an explicit desktop mode selection, not a silent default.

## Implementation Outline

- Add an Axiom-local `pkgs.writeShellScriptBin "axiom-sleep-mode"` in `hosts/axiom/default.nix`.
- Add desktop launcher entries using the existing `mkLauncherEntry` helper:
  - `Power Mode: No Sleep`
  - `Power Mode: Allow Sleep`
  - `Power Mode: Toggle Sleep`
- Add `axiom-no-sleep-inhibit.service` as a systemd user service without `wantedBy`; it is controlled by the script.
- Add `axiom-sleep-mode-apply.service` wanted by `hyprland-session.target` so the selected mode is applied when the desktop session starts.
- Override `home.configFile."hypr/hypridle.conf".text` for Axiom so the existing suspend listener calls `axiom-sleep-mode maybe-suspend`.
- Leave the repository's global `config/hypr/hypridle.conf` unchanged for other hosts.

## Rollback

Rollback is a normal git revert of the PR. Operationally, if the script/service causes trouble before a rebuild rollback is available, the user can run:

```sh
systemctl --user stop axiom-no-sleep-inhibit.service
axiom-sleep-mode allow-sleep
```

If the command is unavailable, stopping `axiom-no-sleep-inhibit.service` removes the direct sleep blocker for the current user session.

## Verification

- Targeted Nix evaluation should assert:
  - Axiom generated `hypr/hypridle.conf` contains `axiom-sleep-mode maybe-suspend`.
  - The global `config/hypr/hypridle.conf` remains unchanged.
  - Axiom defines `axiom-no-sleep-inhibit.service` with `systemd-inhibit --what=sleep --mode=block`.
  - Axiom defines `axiom-sleep-mode-apply.service` under `hyprland-session.target`.
  - Axiom user package/desktop launcher closure includes the `axiom-sleep-mode` command and power-mode launcher entries where feasible to assert.
- Run `git diff --check`.
- Run `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link`, or record the strongest feasible substitute if this environment cannot build.
- Do not trigger live suspend or hibernate from this tool session.

## Post-Deploy Smoke

On the live Axiom desktop after switching the system:

- Confirm `axiom-sleep-mode status` reports no-sleep by default when no state is set.
- Confirm the desktop launcher entries can switch no-sleep and allow-sleep.
- Confirm `systemd-inhibit --list` shows the Axiom no-sleep inhibitor while no-sleep mode is active.
- Confirm idle still locks and turns DPMS off, but does not suspend in no-sleep mode.
- Confirm allow-sleep mode permits the existing Hypridle suspend behavior when deliberately selected.
