## Summary

- Fix the Caelestia DPMS closure mismatch: the shell QML patch previously
  shipped beside an unpatched C++ `Caelestia.Config` plugin, so
  `lockDpmsTimeout` was not provided by the plugin the shell loaded.
- Split the Config and shell patches so each applies to its own derivation.
- Replace the shell's exact original direct plugin input with the patched
  plugin, require exactly one replacement, and publish that same derivation as
  `passthru.plugin`.
- Preserve the existing timer behavior, Axiom's `60` setting, the 900/1800
  idle policy, and Hypridle ownership.

## Validation

- PASS: configured package build:
  `nix build --no-link .#nixosConfigurations.axiom.config.modules.desktop.caelestia.package`
  (`docs/test-report.md:34-50`).
- PASS: the built plugin qmltypes artifact registers
  `GeneralIdle.lockDpmsTimeout` as `int` (`docs/test-report.md:24-32`).
- PASS: the configured package has exactly one patched plugin direct input,
  zero original plugin inputs, and `pkg.plugin` points at the patched output
  (`docs/test-report.md:53-69`).
- PASS: the built shell references the patched plugin and has no original
  plugin reference (`docs/test-report.md:69`; `docs/review-change.md:28-34`).
- PASS: RFC and implementation reviews report no blocking findings
  (`docs/review-rfc.md:7-64`; `docs/review-change.md:9-11`).

## Not Run

Deployment and live testing are blocked by the local sudo password requirement:
`sudo -n true` requires authorization (`docs/test-report.md:71-83`). No switch,
Caelestia restart, runtime import-path check, or physical lock/60-second DPMS
test ran. This PR makes no claim about live QML plugin selection or physical
60-second DPMS behavior.
