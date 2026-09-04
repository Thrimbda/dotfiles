# axiom-nvidia-59591-production

## Metadata

- `task-id`: `axiom-nvidia-59591-production`
- `status`: `active`
- `risk`: `medium`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- Axiom's RTX 5090 now runs NVIDIA production driver 595.99.02 rather than the
  shared profile's beta 595.45.04 selection.
- The override is isolated to Axiom and uses its configured kernel package
  set's `mkDriver` helper, so other NVIDIA hosts retain their current package
  selection and the system-wide Nixpkgs baseline remains unchanged.
- Axiom built, switched, rebooted, and passed driver-version, kernel-binding,
  active-generation, system-health, and Hyprland-session checks.
- The implementation is deployed; its Git/PR lifecycle remains active until
  the delivery branch is merged and cleaned up.

## Reusable Decisions

- For a newer NVIDIA production release on one host, use an Axiom-only
  `hardware.nvidia.package` override rather than changing the shared profile.
- Source the exact version and hashes from the Nixpkgs production definition
  and construct it through `config.boot.kernelPackages.nvidiaPackages.mkDriver`.
- Treat the NixOS build, rebooted `nvidia-smi`, `lspci` kernel binding, active
  generation, and graphical-session process as separate deployment evidence.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-nvidia-59591-production/plan.md`
- `log`: `.legion/tasks/axiom-nvidia-59591-production/log.md`
- `tasks`: `.legion/tasks/axiom-nvidia-59591-production/tasks.md`
- `rfc`: `.legion/tasks/axiom-nvidia-59591-production/docs/rfc.md`
- `test-report`: `.legion/tasks/axiom-nvidia-59591-production/docs/test-report.md`
- `reviews`: `.legion/tasks/axiom-nvidia-59591-production/docs/review-rfc.md`, `.legion/tasks/axiom-nvidia-59591-production/docs/review-change.md`
- `report`: `.legion/tasks/axiom-nvidia-59591-production/docs/report-walkthrough.md`
