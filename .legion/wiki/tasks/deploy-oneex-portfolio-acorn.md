# deploy-oneex-portfolio-acorn

## Metadata

- `task-id`: `deploy-oneex-portfolio-acorn`
- `status`: `historical`
- `risk`: `medium`
- `schema-version`: `v1`
- `historical`: `true`
- `supersedes`: `(none)`
- `superseded-by`: `decommission-oneex-portfolio-account`

## Outcome Summary

- At delivery time, a 1Ex portfolio Custom Account Source adapter was deployed on Acorn behind `https://1ex-portfolio.0xc1.wang`.
- The historical service was loopback-only, used a dedicated unprivileged user and age-encrypted identity environment, and was exposed through nginx TLS.
- The tracked vendor snapshot exactly matches upstream `8dcf21f` before the Nix-only 5.8-second read-timeout patch.
- Local closure build, remote activation, ACME, public DNS, unauthenticated `401`, and authenticated live positions evidence all passed.
- Implementation PR [#161](https://github.com/Thrimbda/dotfiles/pull/161) merged as `670f844c`.
- `decommission-oneex-portfolio-account` later retired this deployment through PR #203. Current Acorn runtime has no adapter unit, process, listener, ACME unit, or nginx vhost; the dormant module, package, and secret artifacts remain intentionally.

## Reusable Decisions

- Use a tracked, explicitly pinned snapshot for a private source that a pure Nix flake cannot fetch.
- Keep adapter processes on loopback and let nginx own public TLS; secrets stay in age ciphertext, not in Nix expressions or task documents.
- Validate fake-IP environments through public DoH plus an independent hostname request, while direct SNI verifies the origin path.

## Related Raw Sources

- `plan`: `.legion/tasks/deploy-oneex-portfolio-acorn/plan.md`
- `log`: `.legion/tasks/deploy-oneex-portfolio-acorn/log.md`
- `tasks`: `.legion/tasks/deploy-oneex-portfolio-acorn/tasks.md`
- `rfc`: `.legion/tasks/deploy-oneex-portfolio-acorn/docs/rfc.md`
- `reviews`: `.legion/tasks/deploy-oneex-portfolio-acorn/docs/review-rfc.md`, `.legion/tasks/deploy-oneex-portfolio-acorn/docs/review-change.md`
- `report`: `.legion/tasks/deploy-oneex-portfolio-acorn/docs/report-walkthrough.md`
