# c1ctl-hey-rust-migration

## Metadata

- `task-id`: `c1ctl-hey-rust-migration`
- `status`: `active`
- `risk`: `high`
- `schema-version`: `2026-06-legion-wiki`
- `historical`: `false`
- `supersedes`: `axiomctl-cli-consolidation`
- `superseded-by`: `(none)`

## Outcome Summary

This task renames the Rust control CLI from `axiomctl` to `c1ctl` and starts the staged Rust migration of non-Rofi `hey` functionality. The first slice keeps Axiom mode switching, status, and reload behavior while adding Rust-owned `path`, `which`, `help`, direct path dispatch, `.foo`, non-Rofi `@namespace`, `wm`, `host`, `theme`, and `exec` foundation behavior.

High-impact mutating command families remain delegated to existing Janet `hey` until follow-up tasks migrate them with parity evidence. Rofi is explicitly not ported: `@rofi` delegates whole to Janet `hey`, and Rust must not resolve or execute Rofi scripts directly.

## Reusable Decisions

- Use `c1ctl` as the durable Rust control CLI name and package path under `packages/c1ctl`.
- Preserve fixed-argv privileged `systemctl` behavior for `c1ctl mode cli` and `c1ctl mode desktop`.
- Migrate `hey` from Janet to Rust in staged command-family slices; do not delete Janet `hey` until parity and rollback evidence exists.
- Treat `@rofi` as an exact delegation boundary. Reject namespace bypass forms such as `@@rofi` or path-like namespaces rather than resolving them in Rust.
- Rust-executed dynamic scripts must receive `DOTFILES_HOME`, computed `PATH`, `HEYSCRIPT`, `HEYDRYRUN`, and `HEYDEBUG`; process execution must use argv arrays, not shell strings.

## Related Raw Sources

- `plan`: `.legion/tasks/c1ctl-hey-rust-migration/plan.md`
- `log`: `.legion/tasks/c1ctl-hey-rust-migration/log.md`
- `tasks`: `.legion/tasks/c1ctl-hey-rust-migration/tasks.md`
- `rfc`: `.legion/tasks/c1ctl-hey-rust-migration/docs/rfc.md`
- `rfc-review`: `.legion/tasks/c1ctl-hey-rust-migration/docs/review-rfc.md`
- `test-report`: `.legion/tasks/c1ctl-hey-rust-migration/docs/test-report.md`

## Notes

- Live mode switching and graphical reload remain post-deploy Axiom smoke checks.
- Follow-up migration candidates include hooks, vars, and Nix rebuild/profile helpers, but each should carry its own scoped parity and rollback evidence.
