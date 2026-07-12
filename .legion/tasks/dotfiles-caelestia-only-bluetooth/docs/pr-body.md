## Summary

- Make the shared Bluetooth profile global and single-surface: BlueZ/CLI remain everywhere, while Caelestia is the only visible GUI on Caelestia-enabled hosts; stock Blueman, Rofi Bluetooth, and Blueman-specific Hyprland rules are removed.
- Add a user-scoped, headless AuthAgent that reuses pinned Blueman pairing UI through one persistent system-bus connection without loading applet, power, rfkill, tray, manager, or mechanism surfaces.
- Add an idempotent Bluetooth-only rfkill finalizer. Ordinary hosts use per-invocation `systemd-rfkill.service` `ExecStopPost`; Ramen/TLP uses cycle-free `tlp.service` weak-Wants, per-device `@%k` helpers, and the existing post-resume path.
- Patch Caelestia's primary five-device list to prefer connected, paired/bonded, and human-named devices while keeping anonymous devices available on the full pairing page.
- Keep pairing values out of runner logs, desktop notifications, Caelestia notification memory, and `notifs.json` by using local GTK dialogs only.

## Verification

- Final RFC Revision 5 review: **PASS**.
- Final `verify-change`: **PASS**. Actual Ramen graph matched the bounded full unit tree (82 services / 105 units); pinned `systemd-analyze verify multi-user.target` returned status 0 with zero diagnostic bytes, while the old graph negative control was rejected for cycle/job-deletion diagnostics.
- Fresh faithful NixOS VM: 22 unique TLP/rfkill InvocationIDs across init success/failure/timeout, boot, real udev ADD, three concurrent base/template jobs, helper recovery, and resume success/failure; stock rfkill stayed masked and WLAN/TLP deltas were zero.
- Auth/privacy gates: 18 Nix tests without skips, 7 private-D-Bus Agent1 interactions, `Notify=0`, Caelestia memory/state delta 0, and zero PIN/passkey/MAC/object-path sentinel leaks.
- Ordinary real-systemd fixture, Caelestia policy/hash fixture, five-host focused eval/builds, synthetic Caelestia-off and Bluetooth-off boundaries, and the full Axiom toplevel build all passed.
- Final security-focused `review-change`: **PASS**, no blocking findings.

## Deployment / Risk

- No generation was deployed or activated. Verification did not call host `systemctl`, BlueZ, rfkill, TLP, or real pairing hardware, and did not change live Bluetooth/rfkill state; runtime systemd operations were isolated in QEMU/private fixtures.
- Deploy-only gates remain for Axiom real pairing/privacy, MediaTek late-add/reboot/resume, Ramen TLP/WLAN boot/add/resume, and per-host smoke checks.
- Known unrelated baselines remain outside this PR: pnpm policy / Ramen font rename, Harusame/Udon Godot rename, Atlas Docker policy, and the existing `xorg.xrandr` warning.
- Roll back by component first: Caelestia policy, rfkill wiring, or AuthAgent (temporary `bluetoothctl agent KeyboardDisplay`). Do not restore the old TLP cycle, `tlp-sleep` hook, or stock Blueman as the first response.
- The standalone HTML walkthrough is committed as an artifact. This repository has no Pages preview workflow, so this PR intentionally does not add unrelated public hosting infrastructure.

## Evidence

- `.legion/tasks/dotfiles-caelestia-only-bluetooth/docs/rfc.md`
- `.legion/tasks/dotfiles-caelestia-only-bluetooth/docs/review-rfc.md`
- `.legion/tasks/dotfiles-caelestia-only-bluetooth/docs/test-report.md`
- `.legion/tasks/dotfiles-caelestia-only-bluetooth/docs/review-change.md`
- `.legion/tasks/dotfiles-caelestia-only-bluetooth/docs/report-walkthrough.md`
- `.legion/tasks/dotfiles-caelestia-only-bluetooth/docs/report-walkthrough.html`
