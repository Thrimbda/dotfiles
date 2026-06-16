## Summary

- migrate NixOS system construction to `readOnlyPkgs` + `nixpkgs.pkgs` without `specialArgs.pkgs`
- add `hostSystem` for import-time platform branching now that module `pkgs` is read-only/config-provided
- replace reported deprecated references: `mesa.drivers`, `pkgs.system`, and `hardware.pulseaudio`

## Testing

- `nix eval --impure --json .#hostMetadata`
- `nix eval --impure --raw .#nixosConfigurations.axiom.config.system.build.toplevel.drvPath`
- `nix build --impure --dry-run .#nixosConfigurations.axiom.config.system.build.toplevel`
- source searches for exact deprecated local references

## Notes

- Full all-host NixOS evaluation is currently blocked by an unrelated existing `godot_4-export-templates` package rename.
- Darwin toplevel evaluation is limited on this Linux machine by unavailable `aarch64-darwin` build support.
