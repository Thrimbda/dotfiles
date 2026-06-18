## Summary

- Add native Hyprland mouse bindings for moving and resizing windows.
- Add `SUPER+SHIFT` mouse-wheel bindings to move the active window to adjacent workspaces.
- Document the new mouse controls in the generated Axiom keybinding help text.

## Scope

- Production change is limited to `modules/desktop/hyprland.nix`.
- Does not modify Caelestia Shell source, Quickshell QML, second-monitor workspace generation, Darwin config, application placement, or workspace numbering.

## Verification

- PASS: generated keybind eval confirms all four mouse bindings are present.
- PASS: `git diff --check`.
- PASS: assembled generated Hyprland config returns `config ok` from `Hyprland --verify-config`.
- PASS: readiness review in `.legion/tasks/axiom-hyprland-mouse-workspace-move/docs/review-change.md`.

## Manual Follow-Up

Live physical mouse behavior still needs a post-deploy smoke test inside the real Axiom Hyprland session.
