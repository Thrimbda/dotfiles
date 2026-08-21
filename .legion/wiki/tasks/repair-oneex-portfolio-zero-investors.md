# repair-oneex-portfolio-zero-investors

## Metadata

- `task-id`: `repair-oneex-portfolio-zero-investors`
- `status`: `in_progress`
- `risk`: `high`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- `My Portfolio` was intended as a private total-assets NAV viewer, but a prior
  owner profile and positive initial cash flow left a fictitious deposit,
  investor, and issued-share projection beside Trading NAV.
- After explicit user approval and fresh event preflight, the repair removed
  only those two events in cash-flow-then-profile order. Each delete was
  followed by a reducer/event read before continuing.
- The Fund remains private, enabled, and closed to subscriptions. It now has
  zero active investors, shares, deposit, and Funding Account balance; one
  successful fresh Trading NAV sample equals current total assets.
- Intermittent source failures are handled with bounded read-only retries only;
  no future outage should recreate a cash flow, investor, or share position.

## Reusable Decisions

- A personal portfolio viewer Fund should not receive an artificial owner
  investment to manufacture unit-price movement. Its source-backed total-assets
  NAV is the intended value surface.
- Delete an erroneous initial investment only after a live source/event gate,
  cash flow before profile, and fresh post-delete state selection. Do not use a
  negative cash flow, redemption, or broad history rewrite as compensation.
- Retry only idempotent source reads on transient `502`; inspect state before
  any subsequent write and skip a Fund upsert when subscriptions are already
  closed.

## Related Raw Sources

- `plan`: `.legion/tasks/repair-oneex-portfolio-zero-investors/plan.md`
- `log`: `.legion/tasks/repair-oneex-portfolio-zero-investors/log.md`
- `tasks`: `.legion/tasks/repair-oneex-portfolio-zero-investors/tasks.md`
- `rfc`: `.legion/tasks/repair-oneex-portfolio-zero-investors/docs/rfc.md`
- `reviews`: `.legion/tasks/repair-oneex-portfolio-zero-investors/docs/review-rfc.md`, `.legion/tasks/repair-oneex-portfolio-zero-investors/docs/review-change.md`
- `test report`: `.legion/tasks/repair-oneex-portfolio-zero-investors/docs/test-report.md`
- `report`: `.legion/tasks/repair-oneex-portfolio-zero-investors/docs/report-walkthrough.md`

## Notes

- The production repair is complete; repository closeout remains pending until
  its PR is merged, the task checklist is finalized, and the worktree lifecycle
  is complete.
- The public Fund detail may need a normal browser refresh to fetch the repaired
  server projection. Runtime credentials, bearer values, seed material, and
  source headers were not recorded.
