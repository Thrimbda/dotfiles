# Acorn Aliyun Host Profile Rename

## Metadata

- `task-id`: `acorn-aliyun-host-rename`
- `status`: `completed`
- `risk`: `medium`
- `schema-version`: `2026-07-07`
- `historical`: `false`
- `supersedes`: `aliyun-acorn active host identity`
- `superseded-by`: `(none)`

## Outcome Summary

- The active public Aliyun-hosted server profile is now `hosts/acorn` and `nixosConfigurations.acorn`.
- The old Azure/development-oriented `hosts/acorn` profile was removed; the former `hosts/aliyun-acorn` profile now owns the canonical `acorn` identity.
- The target runtime hostName is `acorn`; `nixosConfigurations.aliyun-acorn` is intentionally absent.
- Historical `aliyun-acorn-*` task summaries remain historical records and should not be read as current active path/attr truth.

## Reusable Decisions

- Do not keep a compatibility alias for `nixosConfigurations.aliyun-acorn` unless a future scoped task proves an external persisted consumer requires it.
- Aliyun provider context remains valid for the ECS image/runbook, but repository host identity should be `acorn`.
- Age secret files moved with the host profile; public key material was preserved and no secret rotation/decryption occurred in this task.

## Related Raw Sources

- `plan`: `.legion/tasks/acorn-aliyun-host-rename/plan.md`
- `log`: `.legion/tasks/acorn-aliyun-host-rename/log.md`
- `tasks`: `.legion/tasks/acorn-aliyun-host-rename/tasks.md`
- `rfc`: `.legion/tasks/acorn-aliyun-host-rename/docs/rfc.md`
- `rfc-review`: `.legion/tasks/acorn-aliyun-host-rename/docs/review-rfc.md`
- `test-report`: `.legion/tasks/acorn-aliyun-host-rename/docs/test-report.md`
- `change-review`: `.legion/tasks/acorn-aliyun-host-rename/docs/review-change.md`
- `report`: `.legion/tasks/acorn-aliyun-host-rename/docs/report-walkthrough.md`

## Notes

- Remote ECS boot, SSH reachability, ACME issuance, and service health still require a separate deploy/validation task.
- External automation outside this repository that used `aliyun-acorn` paths or attrs must be updated outside this PR.
