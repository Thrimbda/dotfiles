# restore-oneex-portfolio-audience-nav

## Metadata

- `task-id`: `restore-oneex-portfolio-audience-nav`
- `status`: `completed`
- `risk`: `high`
- `schema-version`: `current`
- `historical`: `true`
- `supersedes`: `(none)`
- `superseded-by`: `decommission-oneex-portfolio-account` (active adapter runtime only)

## Outcome Summary

- At the time, the active Acorn adapter was older than its tracked vendor source and minted an
  `auth.ntnl.io` audience that 1Exchange rejected. PR
  [#184](https://github.com/Thrimbda/dotfiles/pull/184) forced a fresh output
  from the unchanged vendor source, then the merged Axiom-to-Acorn deployment
  restored the source to HTTP `200` with six positions and no recursive Fund row.
- The temporary owner investor and issued-unit baseline from this recovery were
  later explicitly removed by `repair-oneex-portfolio-zero-investors`. The
  last verified Fund state was a zero-investor NAV-only viewer. The adapter
  runtime recovery is historical after `decommission-oneex-portfolio-account`;
  that task did not mutate or re-verify external Fund/source metadata.
- The post-write `502` was contained without retrying or creating a duplicate
  financial event. Future upstream failures remain fail-closed operational
  incidents, not prompts to create more cash flows or shares.
- Documentation closeout PR [#185](https://github.com/Thrimbda/dotfiles/pull/185)
  merged after the deployment, verification, review, walkthrough, and wiki
  evidence were complete.

## Reusable Decisions

- If this adapter is redeployed, device-session authentication must send the 1Exchange base
  URL as `redirect_uri` to mint the required `1ex.ntnl.io` audience.
- When a correct vendor source is blocked by a registered-but-missing Nix
  output, use a version-only fresh derivation identity and deploy from merged
  Axiom state; do not delete a live registered store path or change secrets.
- A failed post-write NAV sample stops the accounting operation. The former
  owner-baseline decision is superseded for this Fund: do not issue another
  investor, cash flow, or share position.

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
