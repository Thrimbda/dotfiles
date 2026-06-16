# Log

- 2026-06-16: Created task contract from user-reported Nix evaluation warnings.
- 2026-06-16: Added `nixpkgs.nixosModules.readOnlyPkgs` and removed NixOS `specialArgs.pkgs`; retained explicit `nixpkgs.pkgs = hostInfo.pkgs`.
- 2026-06-16: Added `hostSystem` as an import-time platform selector so modules do not force module `pkgs` before `readOnlyPkgs` provides it.
- 2026-06-16: Replaced `mesa.drivers` with `mesa`, `pkgs.system` with `pkgs.stdenv.hostPlatform.system`, and `hardware.pulseaudio` with `services.pulseaudio`.
- 2026-06-16: Removed/limited NixOS `nixpkgs.overlays` writes that were previously ignored under externally supplied pkgs.
- 2026-06-16: Verification passed for `nix eval --impure --raw .#nixosConfigurations.axiom.config.system.build.toplevel.drvPath` and `nix build --impure --dry-run .#nixosConfigurations.axiom.config.system.build.toplevel` with no reported warning strings.
- 2026-06-16: Full NixOS host batch evaluation remains blocked by unrelated pre-existing `godot_4-export-templates` package rename.
- 2026-06-16: Review-change PASS; security lens applied because SSH/cloudflared files were touched, with no auth or network behavior changes found.
- 2026-06-16: Wrote implementation walkthrough and PR body under task docs.
- 2026-06-16: Wrote Legion wiki task summary, current NixOS read-only pkgs decision, validation pattern, and maintenance follow-up.
