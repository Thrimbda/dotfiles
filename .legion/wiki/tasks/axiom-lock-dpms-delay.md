# axiom-lock-dpms-delay

## Metadata

- `task-id`: `axiom-lock-dpms-delay`
- `status`: `completed`
- `risk`: `medium`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `axiom-lock-dpms-plugin-fix` (plugin closure implementation only)

## Outcome Summary

- Axiom enables `general.idle.lockDpmsTimeout = 60` through both Caelestia settings paths.
- The initial combined patch added a default-disabled typed setting and observes actual `WlSessionLock.locked`, leaving other hosts inert by default.
- One timer is created per lock epoch; unlock invalidates it, and expiry requires the current lock, immutable epoch, and timer identity before DPMS-off. Input wakes DPMS without unlocking or re-arming.
- The independent 900-second lock and 1800-second DPMS policy remain unchanged, with no second idle daemon or automatic suspend/hibernate path.
- The initial shell-only override did not patch or rebuild Caelestia's separately built Config plugin. `axiom-lock-dpms-plugin-fix` supersedes that package-closure implementation while preserving this task's timer behavior and policy boundary.
- The initial source/build checks did not prove runtime plugin selection. The successor has corrected source/build closure evidence, but deployment, runtime import selection, and graphical-session smoke remain pending sudo authorization.

## Reusable Decisions

- Model a post-lock display timeout from the actual session-lock state, not a lock command or global idle deadline.
- Keep default-disabled pinned-source behavior host-enabled only where needed, including mutable settings that survive deployment.
- Do not infer that a separately built Config plugin was patched from a main-shell `overrideAttrs`; use the corrected split-patch and exact-plugin-replacement pattern.
- Treat source/build evidence as proof of repository policy only; prove lock paths, cancellation, and physical DPMS wake separately in a deployed graphical session.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-lock-dpms-delay/plan.md`
- `log`: `.legion/tasks/axiom-lock-dpms-delay/log.md`
- `tasks`: `.legion/tasks/axiom-lock-dpms-delay/tasks.md`
- `rfc`: `.legion/tasks/axiom-lock-dpms-delay/docs/rfc.md`
- `test-report`: `.legion/tasks/axiom-lock-dpms-delay/docs/test-report.md`
- `reviews`: `.legion/tasks/axiom-lock-dpms-delay/docs/review-rfc.md`, `.legion/tasks/axiom-lock-dpms-delay/docs/review-change.md`
- `report`: `.legion/tasks/axiom-lock-dpms-delay/docs/report-walkthrough.md`
