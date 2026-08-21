# axiom-lock-dpms-delay

## Metadata

- `task-id`: `axiom-lock-dpms-delay`
- `status`: `completed`
- `risk`: `medium`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- Axiom enables `general.idle.lockDpmsTimeout = 60` through both Caelestia settings paths.
- A local patch to the pinned Caelestia source adds a default-disabled typed setting and observes actual `WlSessionLock.locked`, leaving other hosts inert by default.
- One timer is created per lock epoch; unlock invalidates it, and expiry requires the current lock, immutable epoch, and timer identity before DPMS-off. Input wakes DPMS without unlocking or re-arming.
- The independent 900-second lock and 1800-second DPMS policy remain unchanged, with no second idle daemon or automatic suspend/hibernate path.
- Patch/source assertions, effective Axiom configuration evaluation, and the configured Caelestia package build pass. No deployed graphical-session smoke test or deployment ran.

## Reusable Decisions

- Model a post-lock display timeout from the actual session-lock state, not a lock command or global idle deadline.
- Keep default-disabled pinned-source behavior host-enabled only where needed, including mutable settings that survive deployment.
- Treat source/build evidence as proof of repository policy only; prove lock paths, cancellation, and physical DPMS wake separately in a deployed graphical session.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-lock-dpms-delay/plan.md`
- `log`: `.legion/tasks/axiom-lock-dpms-delay/log.md`
- `tasks`: `.legion/tasks/axiom-lock-dpms-delay/tasks.md`
- `rfc`: `.legion/tasks/axiom-lock-dpms-delay/docs/rfc.md`
- `test-report`: `.legion/tasks/axiom-lock-dpms-delay/docs/test-report.md`
- `reviews`: `.legion/tasks/axiom-lock-dpms-delay/docs/review-rfc.md`, `.legion/tasks/axiom-lock-dpms-delay/docs/review-change.md`
- `report`: `.legion/tasks/axiom-lock-dpms-delay/docs/report-walkthrough.md`
