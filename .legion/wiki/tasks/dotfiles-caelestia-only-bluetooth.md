# Dotfiles Caelestia-only Bluetooth Control

## Metadata

- `task-id`: `dotfiles-caelestia-only-bluetooth`
- `status`: `completed in PR #136; live hardware smoke pending`
- `risk`: `medium`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `shared Blueman and Rofi Bluetooth control surfaces`
- `superseded-by`: `(none)`

## Outcome Summary

The shared Bluetooth profile now has one graphical owner: Caelestia when enabled. BlueZ/CLI remain global, while stock Blueman, Rofi Bluetooth, tray/manager/mechanism activation, and Blueman-specific desktop rules are removed. A private user-scoped AuthAgent preserves PIN/passkey interactions without becoming a management surface. Ordinary and TLP hosts use separate Bluetooth-only rfkill convergence paths, and Caelestia's primary list no longer lets anonymous broadcasts displace connected, paired, or named devices. Design, VM/build verification, and security-focused change review passed; real Axiom/Ramen hardware smoke remains a deployment gate.

## Reusable Decisions

- Visible Bluetooth ownership belongs to Caelestia; pairing protocol support is a separate headless backend capability.
- Remove competing UI/activation sources rather than relying on one masked vendor unit.
- Keep pairing values in local dialogs and out of journal, desktop notifications, and shell persistence.
- Preserve WLAN/TLP semantics by splitting ordinary `systemd-rfkill` finalization from TLP boot/add/resume helpers.
- Keep anonymous devices available on the full pairing page, but exclude anonymous unpaired noise from the bounded primary list.

## Related Raw Sources

- `plan`: `.legion/tasks/dotfiles-caelestia-only-bluetooth/plan.md`
- `log`: `.legion/tasks/dotfiles-caelestia-only-bluetooth/log.md`
- `tasks`: `.legion/tasks/dotfiles-caelestia-only-bluetooth/tasks.md`
- `rfc`: `.legion/tasks/dotfiles-caelestia-only-bluetooth/docs/rfc.md`
- `reviews`: `.legion/tasks/dotfiles-caelestia-only-bluetooth/docs/review-rfc.md`, `.legion/tasks/dotfiles-caelestia-only-bluetooth/docs/review-change.md`
- `test-report`: `.legion/tasks/dotfiles-caelestia-only-bluetooth/docs/test-report.md`
- `report`: `.legion/tasks/dotfiles-caelestia-only-bluetooth/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/dotfiles-caelestia-only-bluetooth/docs/pr-body.md`

## Notes

- Implementation PR: https://github.com/Thrimbda/dotfiles/pull/136 (`fee6edab5c41f77cd63c8db569300ff2e21b2929`).
- No generation was deployed and no live Bluetooth/rfkill state changed during repository verification.
- The standalone HTML walkthrough is committed as an artifact; no public Pages preview infrastructure was added.
