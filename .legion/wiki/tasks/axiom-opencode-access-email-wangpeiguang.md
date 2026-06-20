# Axiom Opencode Access Email Allowlist

## Metadata

- `task-id`: `axiom-opencode-access-email-wangpeiguang`
- `status`: `active`
- `risk`: `medium`
- `schema-version`: `2026-05-08-legion-workflow`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

`opencode-axiom.0xc1.space` now allows `wangpeiguangwpg@gmail.com` through Cloudflare Access in addition to `c1@ntnl.io`, `siyuan.arc@gmail.com`, and `froggy2818@gmail.com`.

Cloudflare API readback verified the self-hosted app remains Google-only with `auto_redirect_to_identity = true`, exactly one allow policy contains the four exact emails, and no unsafe broad/bypass allow policy exists.

`opencode-charlie.0xc1.space` remains unchanged with `c1@ntnl.io` and `siyuan.arc@gmail.com`. `status-axiom.0xc1.space` was not modified and should not automatically inherit future opencode allowlist changes without a separate scoped task.

## Reusable Decisions

- Opencode Access allowlist changes should be exact-email additions and should keep Google as the only allowed/required identity provider.
- Axiom cloudflared age credentials are tunnel runtime material, not Cloudflare Access API bearer tokens.
- When a service historically matched another service's allowlist, future allowlist changes should not automatically expand both services unless the task scope explicitly says so.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-opencode-access-email-wangpeiguang/plan.md`
- `log`: `.legion/tasks/axiom-opencode-access-email-wangpeiguang/log.md`
- `tasks`: `.legion/tasks/axiom-opencode-access-email-wangpeiguang/tasks.md`
- `verification`: `.legion/tasks/axiom-opencode-access-email-wangpeiguang/docs/test-report.md`
- `review`: `.legion/tasks/axiom-opencode-access-email-wangpeiguang/docs/review-change.md`
- `report`: `.legion/tasks/axiom-opencode-access-email-wangpeiguang/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/axiom-opencode-access-email-wangpeiguang/docs/pr-body.md`
