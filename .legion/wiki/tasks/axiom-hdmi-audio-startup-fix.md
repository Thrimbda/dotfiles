# axiom-hdmi-audio-startup-fix

## Metadata

- `task-id`: `axiom-hdmi-audio-startup-fix`
- `status`: `completed`
- `risk`: `low`
- `schema-version`: `legion-workflow-2026-05`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

This task fixed the repeated axiom no-audio startup failure where Zen/Sidra browser streams landed on the EasyEffects virtual sink while the real NVIDIA DP/HDMI sink was missing. Direct ALSA playback to the DELL U2720QM monitor headphone path worked, so the durable fix is startup ordering and default sink creation rather than hardware or browser package changes.

Current axiom audio startup now creates a user-level `axiom-hdmi-audio.service` oneshot after PipeWire/WirePlumber, reselects the NVIDIA HDMI profile, sets `alsa_output.pci-0000_01_00.1.hdmi-stereo` as default, and orders EasyEffects after that readiness step. EasyEffects remains installed as optional processing, not as the source of truth for output selection.

## Reusable Decisions

- For axiom monitor-headphone output, treat `alsa_output.pci-0000_01_00.1.hdmi-stereo` as the real output source of truth and order EasyEffects after it exists.
- For PipeWire/EasyEffects no-audio regressions, prove the ALSA hardware path separately before changing application packages; then inspect app streams, virtual sinks, and systemd user ordering.
- Final runtime proof still requires a post-deploy fresh graphical session because Nix build/eval cannot prove live stream routing by itself.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-hdmi-audio-startup-fix/plan.md`
- `log`: `.legion/tasks/axiom-hdmi-audio-startup-fix/log.md`
- `tasks`: `.legion/tasks/axiom-hdmi-audio-startup-fix/tasks.md`
- `test-report`: `.legion/tasks/axiom-hdmi-audio-startup-fix/docs/test-report.md`
- `review`: `.legion/tasks/axiom-hdmi-audio-startup-fix/docs/review-change.md`
- `report`: `.legion/tasks/axiom-hdmi-audio-startup-fix/docs/report-walkthrough.md`
