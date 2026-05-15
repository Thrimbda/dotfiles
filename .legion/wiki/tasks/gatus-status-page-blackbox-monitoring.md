# gatus-status-page-blackbox-monitoring

## Metadata

- `task-id`: `gatus-status-page-blackbox-monitoring`
- `status`: `completed`
- `risk`: `medium`
- `schema-version`: `legion-workflow-current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- Gatus is now the repo-managed status page and black-box monitoring entrypoint for `acorn`.
- The first deployment uses NixOS config, not Docker Compose: `modules.services.gatus` wraps upstream `services.gatus`, binds the web UI to `127.0.0.1:8080`, and exposes it through nginx at `status.0xc1.space`.
- Initial endpoints cover `vault.0xc1.space`, the local Gatus status page, and `opencode-axiom.0xc1.space` route/TLS health.
- Prometheus is enabled on `acorn` and scrapes Gatus `/metrics` through the generated `gatus` scrape job.
- Runtime DNS/ACME/status-page reachability remains a post-deploy manual check.

## Reusable Decisions

- For this repo, Gatus status page deployment should follow the NixOS host/module pattern rather than adding Docker Compose as a parallel deployment stack.
- Public Gatus endpoints should stay public-safe; do not add private database, Redis, queue, or internal-only hostnames to the public status page without a new security review.
- Let upstream `services.gatus` own runtime state with `DynamicUser=true` and `StateDirectory=gatus`; do not add custom tmpfiles ownership for `/var/lib/gatus` unless the upstream service model changes.
- For Git-backed flake validation with new module files, use `git add -N` before `nix eval`/`nix build` so the flake source includes new files.

## Related Raw Sources

- `plan`: `.legion/tasks/gatus-status-page-blackbox-monitoring/plan.md`
- `log`: `.legion/tasks/gatus-status-page-blackbox-monitoring/log.md`
- `tasks`: `.legion/tasks/gatus-status-page-blackbox-monitoring/tasks.md`
- `rfc`: `.legion/tasks/gatus-status-page-blackbox-monitoring/docs/rfc.md`
- `review-rfc`: `.legion/tasks/gatus-status-page-blackbox-monitoring/docs/review-rfc.md`
- `test-report`: `.legion/tasks/gatus-status-page-blackbox-monitoring/docs/test-report.md`
- `review-change`: `.legion/tasks/gatus-status-page-blackbox-monitoring/docs/review-change.md`
- `report`: `.legion/tasks/gatus-status-page-blackbox-monitoring/docs/report-walkthrough.md`

## Notes

- `nix build .#nixosConfigurations.acorn.config.system.build.toplevel --no-link` passed for the scoped change.
- `nix flake check --no-build` currently fails on unchanged `apps.install = mkApp ./install.zsh` / `lib/nixos.nix`; treat this as a baseline maintenance issue, not as Gatus evidence.
