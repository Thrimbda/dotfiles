# Axiom Install ToDesk

## Metadata

- `task-id`: `axiom-install-todesk`
- `status`: `active`
- `risk`: `low`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

This task makes ToDesk available on the `axiom` NixOS host through the declarative dotfiles configuration. The implementation adds `todesk` to the existing host-local `user.packages` list in `hosts/axiom/default.nix`.

The current effective conclusion is package-only installation: no ToDesk daemon/service, firewall rule, desktop module, or live `nixos-rebuild switch` is part of this task. Verification confirms pinned `pkgs.todesk` is available for `x86_64-linux` and that the axiom configuration evaluates with `hasTodesk = true`.

Runtime ToDesk behavior remains a post-switch/manual check because this task intentionally avoids live-system changes.

## Reusable Decisions

- For a one-off, host-specific desktop application request on `axiom`, prefer the existing host-local `user.packages` list over introducing a reusable module.
- Remote desktop packages should not imply daemon/service enablement unless the task explicitly asks for runtime remote-access integration.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-install-todesk/plan.md`
- `log`: `.legion/tasks/axiom-install-todesk/log.md`
- `tasks`: `.legion/tasks/axiom-install-todesk/tasks.md`
- `test-report`: `.legion/tasks/axiom-install-todesk/docs/test-report.md`
- `review`: `.legion/tasks/axiom-install-todesk/docs/review-change.md`
- `walkthrough`: `.legion/tasks/axiom-install-todesk/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/axiom-install-todesk/docs/pr-body.md`

## Notes

- After this branch is applied to axiom, switch the host configuration and launch `todesk` manually to confirm runtime UI/login behavior.
