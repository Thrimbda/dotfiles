# axiom-rustdesk-fixed-dp4-capture

## Metadata

- `task-id`: `axiom-rustdesk-fixed-dp4-capture`
- `status`: `active`
- `risk`: `medium`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- Axiom's XDPH picker already selects physical output `DP-4`; a virtual output
  is not appropriate because it would expose a separate desktop.
- RustDesk 1.4.9 persists its Wayland restore token in `RustDesk2.toml`, but
  the c1 server inherited root's config path and could not write it.
- The prepared change keeps root password state in `RustDesk.toml` and gives c1
  ownership only of `RustDesk2.toml` with sticky-directory containment.
- Full build and generated-unit verification passed. Deployment and two remote
  connection checks are still required before this becomes effective truth.

## Reusable Decisions

- Do not solve physical-session capture with a virtual display when the required
  target is an existing output.
- Keep permanent-password storage root-owned; isolate non-secret portal restore
  state instead of moving the complete RustDesk configuration to the desktop
  user's home.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-rustdesk-fixed-dp4-capture/plan.md`
- `log`: `.legion/tasks/axiom-rustdesk-fixed-dp4-capture/log.md`
- `tasks`: `.legion/tasks/axiom-rustdesk-fixed-dp4-capture/tasks.md`
- `rfc`: `.legion/tasks/axiom-rustdesk-fixed-dp4-capture/docs/rfc.md`
- `reviews`: `.legion/tasks/axiom-rustdesk-fixed-dp4-capture/docs/review-rfc.md`, `.legion/tasks/axiom-rustdesk-fixed-dp4-capture/docs/review-change.md`
- `report`: `.legion/tasks/axiom-rustdesk-fixed-dp4-capture/docs/report-walkthrough.md`

## Notes

- The task remains active until the merged configuration has been switched and
  the remote DP-4/no-chooser checks pass.
