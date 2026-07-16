# Auth Mini Gateway Latest Pin

## Metadata

- `task-id`: `auth-mini-gateway-latest-pin`
- `status`: `historical; superseded by auth-mini-node-gateway-migration`
- `risk`: `low`
- `schema-version`: `current`
- `historical`: `true`
- `supersedes`: `(none)`
- `superseded-by`: `auth-mini-node-gateway-migration`

## Outcome Summary

This task pinned auth-mini-gateway to upstream `3e4c273`, matching the version then live-tested on Acorn. Package and Acorn toplevel builds passed, and the four gateway units in the historical all-Acorn topology resolved to that package without service-policy or secret changes. `auth-mini-node-gateway-migration` supersedes this pin with `28a4a273ea9b2725191dce35233f55972beaac6f`.

## Reusable Decision

- Validate a gateway pin refresh at both package and Acorn toplevel levels, including every generated gateway unit path.

## Related Raw Sources

- `.legion/tasks/auth-mini-gateway-latest-pin/plan.md`
- `.legion/tasks/auth-mini-gateway-latest-pin/docs/test-report.md`
- `.legion/tasks/auth-mini-gateway-latest-pin/docs/review-change.md`
- `.legion/tasks/auth-mini-gateway-latest-pin/docs/report-walkthrough.md`
