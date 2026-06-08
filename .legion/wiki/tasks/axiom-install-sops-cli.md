# Axiom Install Sops CLI

## Metadata

- `task-id`: `axiom-install-sops-cli`
- `status`: `active`
- `risk`: `low`
- `schema-version`: `legion-workflow`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

This task makes the `sops` CLI available on the `axiom` NixOS host through the declarative dotfiles configuration. The implementation adds `sops` to the existing host-local `user.packages` list in `hosts/axiom/default.nix`.

The current effective conclusion is CLI-only installation: no `sops-nix`, agenix migration, secret re-encryption, identity change, or live `nixos-rebuild switch` is part of this task. Verification confirms `pkgs.sops` exists, the evaluated `users.users.c1.packages` contains `sops`, and the `axiom` toplevel derivation can be generated.

Live command availability remains a post-switch check: after applying the host configuration, run `sops --version` on `axiom`.

## Reusable Decisions

- For one-off host-specific CLI tools on `axiom`, the host-local `user.packages` list is appropriate when no service, generated config, cross-host module, or runtime policy is required.
- Installing the `sops` CLI does not imply `sops-nix` adoption; declarative secrets integration should be scoped as a separate design task because this repository already uses agenix.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-install-sops-cli/plan.md`
- `log`: `.legion/tasks/axiom-install-sops-cli/log.md`
- `tasks`: `.legion/tasks/axiom-install-sops-cli/tasks.md`
- `test-report`: `.legion/tasks/axiom-install-sops-cli/docs/test-report.md`
- `review-change`: `.legion/tasks/axiom-install-sops-cli/docs/review-change.md`
- `walkthrough`: `.legion/tasks/axiom-install-sops-cli/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/axiom-install-sops-cli/docs/pr-body.md`

## Notes

- If future work introduces `sops-nix`, validate agenix coexistence/migration, identity source, rollback, and secret ownership in a separate task.
