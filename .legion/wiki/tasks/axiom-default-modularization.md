# axiom-default-modularization

## Metadata

- `task-id`: `axiom-default-modularization`
- `status`: `active`
- `risk`: `medium`
- `schema-version`: `2026-06-18`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- Axiom's host configuration now keeps public-service and tunnel facts in `hosts/axiom/default.nix` while moving repeated mechanics into focused service modules.
- `reverse-ssh`, `opencode-server`, and `healthchecks` are reusable NixOS module boundaries instead of large inline systemd blocks in the host file.
- Cloudflared ingress is first-class module data, so opencode can contribute its own public ingress rule and Gatus endpoint from one service declaration.
- Clear duplicate or no-op host settings were removed instead of preserved behind compatibility shims.
- Axiom still evaluates and builds through `nix build .#nixosConfigurations.axiom.config.system.build.toplevel`.

## Reusable Decisions

- For NixOS service refactors, keep host files as fact declarations and move service mechanics, restart policies, health counters, and public integration glue into narrow modules.
- For Git-backed flake validation after adding new modules, stage the new files before `nix eval` or `nix build`; otherwise the flake source can omit untracked module files.
- For Axiom public services, keep local servers bound to loopback and expose them through cloudflared ingress plus Cloudflare Access rather than opening broad firewall ranges.
- Do not keep compatibility aliases for old host-inline service shapes unless another checked-in host actively consumes them.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-default-modularization/plan.md`
- `log`: `.legion/tasks/axiom-default-modularization/log.md`
- `tasks`: `.legion/tasks/axiom-default-modularization/tasks.md`
- `rfc`: `.legion/tasks/axiom-default-modularization/docs/rfc.md`
- `reviews`: `.legion/tasks/axiom-default-modularization/docs/review-rfc.md`, `.legion/tasks/axiom-default-modularization/docs/review-change.md`
- `test-report`: `.legion/tasks/axiom-default-modularization/docs/test-report.md`
- `report`: `.legion/tasks/axiom-default-modularization/docs/report-walkthrough.md`

## Notes

- Live deployment smoke for Cloudflared, autossh, graphical Caelestia, and ToDesk remains runtime validation outside this task's static build proof.
- Broader Hyprland desktop policy cleanup remains a separate task; this change intentionally focused on Axiom host/service modularization.
