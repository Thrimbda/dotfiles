# register-oneex-portfolio-fund

## Metadata

- `task-id`: `register-oneex-portfolio-fund`
- `status`: `completed`
- `risk`: `medium`
- `schema-version`: `v1`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- Registered the deployed adapter as the enabled `1Ex Portfolio Adapter` Custom Account Source.
- Created and enabled the private USD `My Portfolio` Fund with subscriptions closed and one initial NAV.
- Reused the adapter's verified-unused exclusion UUID as the Fund ID, then proved the enabled Fund remains absent from direct adapter output.
- No Acorn configuration or adapter source change was required; runtime credentials remained in Acorn-only memory and cleaned `/run` files.
- Implementation PR [#163](https://github.com/Thrimbda/dotfiles/pull/163) merged as `407b634d`; the source and Fund remain current until an explicit replacement or rollback task.

## Reusable Decisions

- Use an already deployed and verified-unused exclusion ID as the private portfolio Fund ID when it avoids an unnecessary secret deployment.
- Verify a Custom Account Source through unified account discovery, not merely `has_auth_header`, because 1Ex does not return the stored header.
- Treat direct and unified source reads as independent live snapshots; stable position identity plus an immediate fully priced Fund sample is the reliable validation boundary.

## Related Raw Sources

- `plan`: `.legion/tasks/register-oneex-portfolio-fund/plan.md`
- `log`: `.legion/tasks/register-oneex-portfolio-fund/log.md`
- `tasks`: `.legion/tasks/register-oneex-portfolio-fund/tasks.md`
- `rfc`: `.legion/tasks/register-oneex-portfolio-fund/docs/rfc.md`
- `reviews`: `.legion/tasks/register-oneex-portfolio-fund/docs/review-rfc.md`, `.legion/tasks/register-oneex-portfolio-fund/docs/review-change.md`
- `report`: `.legion/tasks/register-oneex-portfolio-fund/docs/report-walkthrough.md`
