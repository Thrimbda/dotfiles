# Charlie Autossh C1 User

## Metadata

- `task-id`: `charlie-autossh-c1-user`
- `status`: `ready-for-deploy`
- `risk`: `low`
- `schema-version`: `2026-07-05-legion-workflow`
- `historical`: `false`
- `supersedes`: `charlie` reverse SSH remote account detail in prior reverse SSH tunnel records
- `superseded-by`: `(none)`

## Outcome Summary

`charlie` 的 declarative autossh reverse SSH 配置现在使用 `c1@8.159.128.125`，不再使用 publickey 失败的 `root@8.159.128.125`。reverse tunnel 形状保持不变：远端 `127.0.0.1:2222` 转发到本机 `127.0.0.1:22`。

Live validation confirmed `c1@8.159.128.125` batch SSH login and a temporary same-shape reverse forward with `ExitOnForwardFailure=yes`. Remote `ssh-keyscan -p 2222 127.0.0.1` saw the forwarded SSH endpoint while the temporary master was running.

The tracked config fix does not remove the home-local unmanaged `~/Library/LaunchAgents/com.charlie.autossh.plist`; after deploying the tracked config, clean up that old agent if it is still loaded so the stale root-based autossh process stops retrying.

## Reusable Decisions

- `charlie` owns remote loopback `127.0.0.1:2222` on `8.159.128.125` for its autossh reverse SSH tunnel.
- `charlie` autossh should authenticate to the remote as `c1`, not `root`.
- Keep the tunnel loopback-only and preserve the local target `127.0.0.1:22` unless a future security review explicitly changes that topology.

## Related Raw Sources

- `plan`: `.legion/tasks/charlie-autossh-c1-user/plan.md`
- `log`: `.legion/tasks/charlie-autossh-c1-user/log.md`
- `tasks`: `.legion/tasks/charlie-autossh-c1-user/tasks.md`
- `rfc`: `.legion/tasks/charlie-autossh-c1-user/docs/rfc.md`
- `test-report`: `.legion/tasks/charlie-autossh-c1-user/docs/test-report.md`
- `change-review`: `.legion/tasks/charlie-autossh-c1-user/docs/review-change.md`
- `report`: `.legion/tasks/charlie-autossh-c1-user/docs/report-walkthrough.md`
