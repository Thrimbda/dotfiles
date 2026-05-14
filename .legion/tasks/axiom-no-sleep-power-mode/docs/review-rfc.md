# RFC Review: Axiom No-Sleep Power Mode

## Verdict

PASS

## Reviewed Artifact

- `.legion/tasks/axiom-no-sleep-power-mode/docs/rfc.md`

## Findings

No blocking findings.

## Review Notes

- The RFC correctly rejects a global Hypridle edit because it would exceed the Axiom-only scope and provide no desktop switch.
- The selected design covers both relevant surfaces: Hypridle auto-suspend is routed through `axiom-sleep-mode maybe-suspend`, and accidental direct sleep requests are blocked by a user sleep inhibitor while no-sleep mode is active.
- Rollback is clear: git revert for the declarative change, and `systemctl --user stop axiom-no-sleep-inhibit.service` as an operational escape hatch.
- Verification is concrete enough before implementation: targeted Nix evals can assert generated Hypridle text and user service shape, `git diff --check` can catch whitespace issues, and the Axiom toplevel build is the right strongest local build check.
- The persistent allow-sleep state is an acceptable product trade-off because it is explicitly user-selected from the desktop, while the missing-state default remains no-sleep.

## Non-Blocking Suggestions

- Keep the script verbs small and fixed; avoid turning `axiom-sleep-mode` into a general power-management framework.
- Include a harmless `status` verb so post-deploy checks can inspect the active mode without triggering suspend.
- If notification support is added, treat `notify-send` as best-effort only so the command still works in non-graphical shells.

## Gate Result

Implementation may proceed using Option D from the RFC.
