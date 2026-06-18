# Axiom Host Script Extraction

## Status
Implementation verified; PR pending.

## Summary
Follow-up to `axiom-default-modularization` after the user pointed out the first pass was still too conservative. The Axiom host now keeps facts and enablement while focused modules own the remaining large inline script/policy bodies.

`hosts/axiom/default.nix` changed from 667 lines to 451 lines.

## Outputs
- `modules/desktop/caelestia.nix` now owns mutable `shell.json` patching, package data-dir injection, and opt-in local-control polkit allowlists.
- `modules/desktop/audio/hdmi.nix` owns the Axiom HDMI/PipeWire readiness unit, priority rules, PulseAudio autospawn prevention, and EasyEffects ordering.
- `modules/services/todesk.nix` owns ToDesk package installation, `/var/lib/todesk` tmpfiles, and the background service.
- `modules/services/healthchecks.nix` now has typed predicates for HTTP readiness, autossh endpoint key checks, and service-core/interface checks.
- `modules/virt/libvirt.nix` owns libvirt/virt-manager/swtpm/packages/groups for desktop VM usage.
- `hosts/axiom/default.nix` now declares Caelestia app/idle facts, HDMI card/sink facts, ToDesk/libvirt enablement, healthcheck facts, tunnel facts, and hardware facts.

## Verification
- `git diff --check` passed.
- Focused Nix facts eval confirmed generated Caelestia, HDMI audio, ToDesk, libvirt/virt-manager, and healthcheck service facts.
- `nix build .#nixosConfigurations.axiom.config.system.build.toplevel` passed.

## Review
`docs/review-change.md` passed. Security lens was applied because polkit and service boundaries changed. The polkit action set did not expand; it moved from host inline JS to an opt-in Caelestia module option.

## Follow-Up
Runtime validation remains post-deploy: restart/switch Axiom, inspect Caelestia mutable config, verify HDMI default sink and EasyEffects ordering, verify ToDesk service/GUI connectivity, check healthcheck timers, and confirm libvirt/virt-manager activation.
