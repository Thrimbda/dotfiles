# RustDesk Self-Hosted Remote Access

## Metadata

- `task-id`: `rustdesk-self-hosted-remote-access`
- `status`: `completed`
- `risk`: `high`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

Acorn runs the self-hosted RustDesk 1.1.14 signal/relay services, and Axiom/Charlie use pinned RustDesk 1.4.9 clients. Acorn's task-owned source patch makes `ALWAYS_USE_RELAY=Y` override the upstream same-intranet `FetchLocalAddr` shortcut, so same-public-IP sessions use hbbr. Charlie v10 provisions the permanent password through the correct GUI launchd domain. Runtime verification passed for relay pairing,画面、鼠标、键盘、correct/wrong password、manual finalizer和fast-skip。

## Reusable Decisions

- Acorn RustDesk traffic is relay-only; while server 1.1.14 retains the upstream same-intranet shortcut, keep the exact source patch and revalidate it on every server upgrade.
- Charlie's root provision helper must use `launchctl asuser "$uid"` when restarting the GUI-domain RustDesk server.
- Acorn builds/deployments must run from Axiom with the repository-mandated `--build-host localhost` command; never build on Acorn.

## Related Raw Sources

- `plan`: `.legion/tasks/rustdesk-self-hosted-remote-access/plan.md`
- `log`: `.legion/tasks/rustdesk-self-hosted-remote-access/log.md`
- `tasks`: `.legion/tasks/rustdesk-self-hosted-remote-access/tasks.md`
- `rfc`: `.legion/tasks/rustdesk-self-hosted-remote-access/docs/rfc.md`
- `reviews`: `.legion/tasks/rustdesk-self-hosted-remote-access/docs/review-change.md`
- `test-report`: `.legion/tasks/rustdesk-self-hosted-remote-access/docs/test-report.md`
- `report`: `.legion/tasks/rustdesk-self-hosted-remote-access/docs/report-walkthrough.md`

## Notes

- Long-term relay bandwidth、capacity、cloud cost和Acorn单点风险仍需运营观测。
- 本轮fresh negative明确覆盖wrong password；old-password与cross-host未分别重跑。
