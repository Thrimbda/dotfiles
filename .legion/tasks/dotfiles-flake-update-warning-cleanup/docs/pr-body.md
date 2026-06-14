# Summary

- Update flake inputs and repair compatibility with the new nixpkgs baseline.
- Fix removed/renamed package attributes, deprecated NixOS options, and the insecure Docker default.
- Remove warnings from the `axiom` `nix build` path, including the `specialArgs.pkgs` warning.

# Validation

- PASS: `nix build .#nixosConfigurations.axiom.config.system.build.toplevel --no-link`
- PASS: final cached rerun of the same build produced no output.
- PASS: `nix flake check --no-build` evaluates compatible outputs and all current-system NixOS hosts.

# Notes

- `nix flake check --no-build` still warns about custom outputs (`hostData`, `hostMetadata`, `hostSystems`, `_heyArgs`) because they are intentionally retained for existing `hey` metadata queries.
- No system switch was run.
