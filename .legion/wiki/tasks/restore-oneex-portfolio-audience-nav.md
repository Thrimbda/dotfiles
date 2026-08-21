# restore-oneex-portfolio-audience-nav

## Metadata

- `task-id`: `restore-oneex-portfolio-audience-nav`
- `status`: `completed`
- `risk`: `high`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- The active Acorn adapter was older than its tracked vendor source and minted an
  `auth.ntnl.io` audience that 1Exchange rejected. PR
  [#184](https://github.com/Thrimbda/dotfiles/pull/184) forced a fresh output
  from the unchanged vendor source, then the merged Axiom-to-Acorn deployment
  restored the source to HTTP `200` with six positions and no recursive Fund row.
- `My Portfolio` now has one owner investor and issued units. A single approved
  corrective NAV sample restored total assets and total shares to the same
  fully priced trading value, so unit price is derived from assets divided by
  shares instead of the zero-share fallback.
- The post-write `502` was contained without retrying or creating a duplicate
  financial event. Future upstream failures remain fail-closed operational
  incidents, not prompts to create more cash flows or shares.

## Reusable Decisions

- Device-session authentication for this adapter must send the 1Exchange base
  URL as `redirect_uri` to mint the required `1ex.ntnl.io` audience.
- When a correct vendor source is blocked by a registered-but-missing Nix
  output, use a version-only fresh derivation identity and deploy from merged
  Axiom state; do not delete a live registered store path or change secrets.
- A failed post-write NAV sample stops the accounting operation. A corrective
  sample needs explicit approval and must not issue another investor, cash
  flow, or share position.

## Related Raw Sources

- `plan`: `.legion/tasks/restore-oneex-portfolio-audience-nav/plan.md`
- `log`: `.legion/tasks/restore-oneex-portfolio-audience-nav/log.md`
- `tasks`: `.legion/tasks/restore-oneex-portfolio-audience-nav/tasks.md`
- `rfc`: `.legion/tasks/restore-oneex-portfolio-audience-nav/docs/rfc.md`
- `reviews`: `.legion/tasks/restore-oneex-portfolio-audience-nav/docs/review-rfc.md`, `.legion/tasks/restore-oneex-portfolio-audience-nav/docs/review-change.md`
- `test report`: `.legion/tasks/restore-oneex-portfolio-audience-nav/docs/test-report.md`
- `report`: `.legion/tasks/restore-oneex-portfolio-audience-nav/docs/report-walkthrough.md`

## Notes

- Runtime credentials, bearer values, seed material, and source headers were
  not recorded in task artifacts or wiki content.
