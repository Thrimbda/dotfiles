# Report Walkthrough: Axiom Host Script Extraction

## Mode
implementation

## Reviewer Summary
This follow-up makes the Axiom host modularization less conservative. `hosts/axiom/default.nix` is now mostly host facts and service enablement; the large inline scripts and policy bodies moved into focused modules.

Host size changed from 667 lines to 451 lines.

## What Changed
- Added `modules/desktop/audio/hdmi.nix` for the Axiom HDMI/PipeWire startup workaround.
- Added `modules/services/todesk.nix` for ToDesk package, tmpfiles, and service setup.
- Added `modules/virt/libvirt.nix` for libvirt, virt-manager, SWTPM, packages, and user groups.
- Extended `modules/desktop/caelestia.nix` with mutable config patching, package data-dir injection, and local-control polkit allowlist support.
- Extended `modules/services/healthchecks.nix` with typed predicates for HTTP readiness, autossh endpoint-key checks, and service-core/interface checks.
- Replaced Axiom inline script bodies with module facts: Caelestia app/idle facts, HDMI card/sink facts, ToDesk enablement, libvirt enablement, and healthcheck predicates.

## Behavior Preserved
- Caelestia still seeds/preserves mutable `shell.json`, applies Axiom idle defaults, adds the Feishu launcher ID, and removes the legacy desktop ID.
- HDMI audio still suppresses stray PulseAudio autospawn, waits for the NVIDIA HDMI card, sets `output:hdmi-stereo`, sets the default sink, and orders before EasyEffects.
- ToDesk still runs as the configured user from the user's home directory with `/var/lib/todesk` state and `on-failure` restart.
- Autossh, Cloudflared, and Clash healthchecks still generate systemd services/timers with restart thresholds.
- Libvirt/virt-manager still enables the same VM stack and packages.
- Polkit action set is unchanged; it is now opt-in via Caelestia local controls.

## Verification
See `docs/test-report.md`.

Passed:
- `git diff --check`
- Focused Nix facts eval for Caelestia, HDMI audio, ToDesk, libvirt/virt-manager, and healthcheck runners
- `nix build .#nixosConfigurations.axiom.config.system.build.toplevel`

## Review
See `docs/review-change.md`.

Decision: PASS.

Security lens was applied because polkit permissions and service boundaries changed. No permission expansion was found.

## Residual Risk
- Runtime behavior was not live-smoked on the workstation session. Deployment should still verify the graphical session, HDMI sink selection, ToDesk service, and healthcheck timers after activation.
