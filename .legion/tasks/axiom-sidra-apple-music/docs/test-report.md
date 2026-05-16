# Test Report: Axiom Sidra Apple Music

## Summary

PASS. The `axiom` NixOS system configuration evaluates and builds successfully with Sidra enabled.

## Commands

```sh
nix eval .#nixosConfigurations.axiom.config.modules.desktop.apps.sidra.enable
```

Result: PASS, returned `true` after staging the newly added module so the Git-backed flake source includes it.

```sh
nix build --dry-run .#nixosConfigurations.axiom.config.system.build.toplevel
```

Result: PASS. The dry-run evaluated the `axiom` toplevel and showed Sidra derivations in the closure, including `Sidra-0.3.3-linux-amd64.deb`, `sidra-unpacked-0.3.3`, and `sidra`.

```sh
nix build --no-link .#nixosConfigurations.axiom.config.system.build.toplevel
```

Result: PASS. The affected `axiom` system toplevel built successfully without producing a local `result` symlink.

## Why These Checks

- The option eval directly proves `hosts/axiom` enables `modules.desktop.apps.sidra`.
- The dry-run proves the NixOS toplevel evaluates with the new flake input and shows Sidra in the build closure.
- The `--no-link` build is stronger than evaluation-only evidence because it fetches/builds the Sidra package path and the resulting system derivation.

## Warnings

- Nix emitted existing evaluation warnings about `specialArgs.pkgs`, deprecated `mesa.drivers`, `system` being renamed to `stdenv.hostPlatform.system`, and `hardware.pulseaudio` being renamed. These warnings are not introduced by the Sidra module and did not fail the build.

## Skipped

- Runtime Apple Music login/playback was not tested because this task only changes declarative installation and does not automate GUI account state.
