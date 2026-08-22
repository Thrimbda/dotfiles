# axiom-lock-dpms-plugin-fix

## Metadata

- `task-id`: `axiom-lock-dpms-plugin-fix`
- `status`: `completed`
- `risk`: `medium`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `axiom-lock-dpms-delay` (plugin closure implementation only)
- `superseded-by`: `(none)`

## Outcome Summary

- The prior shell patch left the separately built Config plugin unpatched; the
  split C++/QML patch and exact plugin replacement now align the live schema and
  shell closure.
- Quickshell 0.3 does not emit `lockedChanged` on lock acquisition. The timer
  now arms only from compositor-confirmed `WlSessionLock.secureChanged`.
- Axiom enables native Hyprland key-press and pointer-motion DPMS wake. This
  wakes the display without releasing the Caelestia lock and also covers the
  approved 1800-second fallback DPMS policy.
- Runtime validation passed: 65-second locked DPMS-off, pointer wake while
  locked, no rearm after another 65 seconds, and display restoration on unlock.
- Implementation PR [#197](https://github.com/Thrimbda/dotfiles/pull/197)
  merged as `b8a57fbc` after the task's build, deployment, review, walkthrough,
  and wiki evidence were complete.

## Reusable Decisions

- A main Caelestia shell `overrideAttrs` does not propagate patches to its separately built Config plugin.
- Replace a plugin dependency by resolved store path with an exact-one-match assertion and update `passthru.plugin`; do not match names or append a second plugin.
- Treat source/build closure proof, deployed plugin import selection, and physical lock/DPMS behavior as separate evidence layers.
- For Quickshell 0.3 session locks, use `secureChanged` rather than
  `lockedChanged` for lock-acquisition actions; retain `lockedChanged` for
  unlock cleanup.
- Prefer compositor-native DPMS wake over lock-surface input plumbing when the
  accepted policy is host-wide physical-input wake.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-lock-dpms-plugin-fix/plan.md`
- `log`: `.legion/tasks/axiom-lock-dpms-plugin-fix/log.md`
- `tasks`: `.legion/tasks/axiom-lock-dpms-plugin-fix/tasks.md`
- `rfc`: `.legion/tasks/axiom-lock-dpms-plugin-fix/docs/rfc.md`
- `test-report`: `.legion/tasks/axiom-lock-dpms-plugin-fix/docs/test-report.md`
- `reviews`: `.legion/tasks/axiom-lock-dpms-plugin-fix/docs/review-rfc.md`, `.legion/tasks/axiom-lock-dpms-plugin-fix/docs/review-change.md`
- `report`: `.legion/tasks/axiom-lock-dpms-plugin-fix/docs/report-walkthrough.md`
