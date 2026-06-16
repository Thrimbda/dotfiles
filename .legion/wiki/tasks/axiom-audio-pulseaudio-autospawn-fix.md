# axiom-audio-pulseaudio-autospawn-fix

## Metadata

- `task-id`: `axiom-audio-pulseaudio-autospawn-fix`
- `status`: `completed`
- `risk`: `low`
- `schema-version`: `legion-workflow-2026-05`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

This follow-up addresses a new Axiom no-audio root cause: a real `pulseaudio --start` daemon autospawned outside PipeWire and held the NVIDIA `hdmi:0` ALSA device, preventing PipeWire from creating the real HDMI sink. Killing real PulseAudio and restarting WirePlumber restored `alsa_output.pci-0000_01_00.1.hdmi-stereo`; stopping EasyEffects then routed the active Cyberpunk stream directly to `MPG272UX OLED`.

The durable configuration now disables PulseAudio client autospawn for the user through `home.configFile."pulse/client.conf"` and hardens the existing Axiom HDMI readiness script to clear stray `pulseaudio` before reselecting the HDMI profile/default sink. PipeWire's PulseAudio-compatible server remains the intended Pulse server on Axiom.

## Reusable Decisions

- On Axiom, a real PulseAudio daemon is not part of the intended audio stack; PipeWire's Pulse server owns PulseAudio compatibility.
- For Axiom HDMI no-audio incidents, check for `pulseaudio --start` in addition to PipeWire default sink, WirePlumber card profile, EasyEffects virtual sink, and app stream routing.
- Disabling PulseAudio autospawn is safe for this host because it intentionally uses PipeWire and has a declarative fallback through Home Manager.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-audio-pulseaudio-autospawn-fix/plan.md`
- `log`: `.legion/tasks/axiom-audio-pulseaudio-autospawn-fix/log.md`
- `tasks`: `.legion/tasks/axiom-audio-pulseaudio-autospawn-fix/tasks.md`
- `test-report`: `.legion/tasks/axiom-audio-pulseaudio-autospawn-fix/docs/test-report.md`
- `review`: `.legion/tasks/axiom-audio-pulseaudio-autospawn-fix/docs/review-change.md`
- `report`: `.legion/tasks/axiom-audio-pulseaudio-autospawn-fix/docs/report-walkthrough.md`
