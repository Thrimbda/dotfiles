# Axiom RustDesk Provision Recovery

## Metadata

- `task-id`: `axiom-rustdesk-provision-recovery`
- `status`: `completed`
- `risk`: `high`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- Axiom's provisioner previously treated a valid current `attempt` as a
  permanent `attempt-used` failure after an interrupted run.
- The deployed source safely clears a validated incomplete attempt and retries,
  while a valid current ready record exits successfully and retains the explicit
  remote-auth finalization boundary.
- Axiom evaluation, a full no-link closure build, generated-script syntax, and
  generated-unit verification passed.
- PR #182 merged and the user-authorized Axiom switch ran the candidate script
  at `2026-08-21 11:45:25 CST` with `0/SUCCESS`; its new journal invocation has
  no `attempt-used` entry.

## Reusable Decisions

- Persistent root state may be removed only after canonical inspection, while
  the operation lock is held, followed by a directory sync and absent-state
  reinspection.
- When provisioning logic changes but its persisted revision semantics do not,
  use the generated script as a `restartTriggers` input rather than invalidating
  valid final stamps with a revision bump.
- A current ready record is local proof of password application pending explicit
  remote-auth confirmation; it is not an automatic final stamp.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-rustdesk-provision-recovery/plan.md`
- `log`: `.legion/tasks/axiom-rustdesk-provision-recovery/log.md`
- `tasks`: `.legion/tasks/axiom-rustdesk-provision-recovery/tasks.md`
- `rfc`: `.legion/tasks/axiom-rustdesk-provision-recovery/docs/rfc.md`
- `reviews`: `.legion/tasks/axiom-rustdesk-provision-recovery/docs/review-rfc.md`, `.legion/tasks/axiom-rustdesk-provision-recovery/docs/review-change.md`
- `test report`: `.legion/tasks/axiom-rustdesk-provision-recovery/docs/test-report.md`
- `report`: `.legion/tasks/axiom-rustdesk-provision-recovery/docs/report-walkthrough.md`

## Notes

- Do not manually finalize a pending ready record without a real remote-auth
  confirmation.
- Mutable state contents were not read or exposed; service success is the
  recorded runtime acceptance signal.
