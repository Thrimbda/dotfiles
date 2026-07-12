# Auth Mini Upstream Release Pin

## Metadata

- `task-id`: `auth-mini-upstream-release-pin`
- `status`: `ready for PR`
- `risk`: `low`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

Dotfiles now pins the auth-mini upstream release generated after Passkey PR #137 merged as `9560660a51ee0e0b0a538e36c0b2883b16281eff`. The package version advances to `latest-2026-07-12`, and its fixed-output hash matches the published Linux release asset. Package and Acorn toplevel builds pass without changing service or secret boundaries.

## Reusable Decisions

- Keep the existing fixed-output hash boundary around the mutable upstream `latest` URL; release movement must fail closed until the package pin is deliberately refreshed and rebuilt.
- For an auth-mini binary refresh, verify both the package derivation and the consuming Acorn toplevel closure.

## Related Raw Sources

- `plan`: `.legion/tasks/auth-mini-upstream-release-pin/plan.md`
- `log`: `.legion/tasks/auth-mini-upstream-release-pin/log.md`
- `tasks`: `.legion/tasks/auth-mini-upstream-release-pin/tasks.md`
- `test-report`: `.legion/tasks/auth-mini-upstream-release-pin/docs/test-report.md`
- `change-review`: `.legion/tasks/auth-mini-upstream-release-pin/docs/review-change.md`
- `report`: `.legion/tasks/auth-mini-upstream-release-pin/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/auth-mini-upstream-release-pin/docs/pr-body.md`

## Notes

- The production diff is limited to package version metadata and the release archive hash.
