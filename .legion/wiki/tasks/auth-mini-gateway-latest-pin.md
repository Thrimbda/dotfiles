# Auth Mini Gateway Latest Pin

## Metadata

- `task-id`: `auth-mini-gateway-latest-pin`
- `status`: `ready for PR`
- `risk`: `low`
- `schema-version`: `current`
- `historical`: `false`

## Outcome Summary

Dotfiles pins auth-mini-gateway to upstream `3e4c273`, matching the version already live-tested on Acorn. Package and Acorn toplevel builds pass, and all four gateway units resolve to the new package without service-policy or secret changes.

## Reusable Decision

- Validate a gateway pin refresh at both package and Acorn toplevel levels, including every generated gateway unit path.

## Related Raw Sources

- `.legion/tasks/auth-mini-gateway-latest-pin/plan.md`
- `.legion/tasks/auth-mini-gateway-latest-pin/docs/test-report.md`
- `.legion/tasks/auth-mini-gateway-latest-pin/docs/review-change.md`
- `.legion/tasks/auth-mini-gateway-latest-pin/docs/report-walkthrough.md`
