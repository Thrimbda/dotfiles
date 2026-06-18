# Walkthrough: Axiom Hyprland Mouse Workspace Move

Mode: implementation

## Reviewer Focus

This change adds native Hyprland mouse bindings to the generated Axiom desktop config. It does not modify Caelestia Shell, Quickshell QML, second-monitor workspace generation, or existing keyboard workspace numbering.

## What Changed

- Added `SUPER + left mouse drag` as `bindm = SUPER, mouse:272, movewindow`.
- Added `SUPER + right mouse drag` as `bindm = SUPER, mouse:273, resizewindow`.
- Added `SUPER+SHIFT + wheel down` as `movetoworkspace, +1`.
- Added `SUPER+SHIFT + wheel up` as `movetoworkspace, -1`.
- Updated the generated keybinding help text to document the new mouse window/workspace controls.

## Files To Review

- `modules/desktop/hyprland.nix`: production change; adds the four generated mouse bindings and help text lines.
- `.legion/tasks/axiom-hyprland-mouse-workspace-move/plan.md`: task contract and scope boundaries.
- `.legion/tasks/axiom-hyprland-mouse-workspace-move/docs/test-report.md`: verification evidence.
- `.legion/tasks/axiom-hyprland-mouse-workspace-move/docs/review-change.md`: readiness review.

## Verification Evidence

- PASS: generated keybind eval returned `{"move":true,"next":true,"previous":true,"resize":true}`.
- PASS: `git diff --check` returned no output.
- PASS: assembled generated Hyprland config returned `config ok` from `Hyprland --verify-config`.

See `docs/test-report.md` for commands and outputs.

## Review Evidence

`docs/review-change.md` returned PASS with no blocking findings. Scope review confirmed no Caelestia source, Quickshell QML, Darwin config, second-monitor workspace generation, application placement, or workspace numbering changes.

## Residual Manual Check

After deployment in the real Axiom Hyprland session, smoke test:

- `SUPER + left mouse drag` moves a focused window.
- `SUPER + right mouse drag` resizes a focused window.
- `SUPER+SHIFT + wheel down/up` moves the active window to adjacent workspaces in the documented direction.
- Pointer events over Caelestia layer-shell UI remain owned by Caelestia surfaces, as expected.
