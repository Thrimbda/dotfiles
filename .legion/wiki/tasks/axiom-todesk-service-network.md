# Axiom ToDesk Service Network

## Metadata

- `task-id`: `axiom-todesk-service-network`
- `status`: `active`
- `risk`: `low`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

This task turns the previous ToDesk package-only install into a usable runtime setup on `axiom` by adding the missing state directory ownership and the ToDesk background service.

The implemented shape is host-local: `/var/lib/todesk` is created with `0700 c1 users`, and `systemd.services.todesk` runs `${pkgs.todesk}/bin/todesk service` as `c1` after `network-online.target`. No firewall rules, package versions, or reusable modules changed.

Verification confirmed the evaluated axiom configuration contains the expected tmpfiles rule and service fields. Live socket evidence showed `ToDesk_Service` owns the external HTTPS connection while the GUI connects to it over localhost.

## Reusable Decisions

- ToDesk's Nix package needs runtime state under `/var/lib/todesk`; create that directory declaratively rather than relying on manual setup.
- When both ToDesk GUI and service run as the desktop user, restrict `/var/lib/todesk` to `0700` because ToDesk writes auth/private state there.
- Do not open firewall ports for this ToDesk service integration without a separate task and security review.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-todesk-service-network/plan.md`
- `log`: `.legion/tasks/axiom-todesk-service-network/log.md`
- `tasks`: `.legion/tasks/axiom-todesk-service-network/tasks.md`
- `test-report`: `.legion/tasks/axiom-todesk-service-network/docs/test-report.md`
- `review`: `.legion/tasks/axiom-todesk-service-network/docs/review-change.md`
- `walkthrough`: `.legion/tasks/axiom-todesk-service-network/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/axiom-todesk-service-network/docs/pr-body.md`

## Notes

- After deployment, run `systemctl status todesk` and launch ToDesk in the graphical session to confirm the GUI no longer reports no network.
