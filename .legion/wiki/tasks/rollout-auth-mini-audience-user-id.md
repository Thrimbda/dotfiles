# rollout-auth-mini-audience-user-id

## Metadata

- `task-id`: `rollout-auth-mini-audience-user-id`
- `status`: `completed`
- `risk`: `high`
- `schema-version`: `gateway-session-v2` (unchanged)
- `historical`: `false`
- `supersedes`: email-or-user-id gateway authorization rollout
- `superseded-by`: `(none)`

## Outcome Summary

- All four auth-mini gateway instances now run the audience-bound `0.1.0-unstable-2026-07-30` package from upstream `e1ea3e77fc39612b7418a3a44db5e2cc2b8618d4`.
- Axiom and Acorn encrypted environments preserve their cookie secrets and contain only the supplied exact auth-mini user ID in `ALLOW_USER_IDS`; `ALLOW_EMAILS` is absent or empty.
- Axiom proxy gateways explicitly select `UPSTREAM_PROTOCOL=http1`, closing the live `upstream_protocol_cleartext_auto` startup failure from the first switch.
- Axiom status/opencode and Acorn auth-gateway/frps services are active, healthy, and return correct auth-mini login redirects.
- Acorn deployment used the mandated Axiom `--build-host localhost` path; no Nix build or rebuild ran on Acorn.

## Reusable Decisions

- Gateway rollout must migrate every host sharing the same package pin before declaring the audience contract deployed.
- Cleartext proxy-mode gateways must set an explicit `UPSTREAM_PROTOCOL`; `http1` is the current Axiom choice.
- User-ID migration belongs only in host-local agenix env files; the supplied ID must not be written to plaintext Nix, task docs, PR bodies, or logs.
- Production rollout evidence must distinguish service/config proof from credential-bearing browser login smoke.

## Related Raw Sources

- `plan`: `.legion/tasks/rollout-auth-mini-audience-user-id/plan.md`
- `log`: `.legion/tasks/rollout-auth-mini-audience-user-id/log.md`
- `tasks`: `.legion/tasks/rollout-auth-mini-audience-user-id/tasks.md`
- `test report`: `.legion/tasks/rollout-auth-mini-audience-user-id/docs/test-report.md`
- `review`: `.legion/tasks/rollout-auth-mini-audience-user-id/docs/review-change.md`
- `report`: `.legion/tasks/rollout-auth-mini-audience-user-id/docs/report-walkthrough.md`
- `pr body`: `.legion/tasks/rollout-auth-mini-audience-user-id/docs/pr-body.md`

## Notes

- PR #157 merged as `8872e1f81947cc5fde20891e013d162d3e8a64ea`.
- PR #158 merged as `fb78aea6a97e3a2b388972cbdfbcf540ed8cfcc2`.
- Credential-bearing browser login remains the user's final smoke check.
- `rustdesk-provision.service` reported `attempt-used` during Axiom activation; it is unrelated and remains outside this task.
