# Report Walkthrough

Mode: implementation.

## What Changed

- NixOS system construction now follows the read-only pkgs pattern: import `nixpkgs.nixosModules.readOnlyPkgs`, set `nixpkgs.pkgs = hostInfo.pkgs`, and stop passing `pkgs` through NixOS `specialArgs`.
- A plain `hostSystem` specialArg now carries the host system string for import-time platform decisions that previously forced `pkgs.stdenv.isLinux` / `pkgs.stdenv.isDarwin` too early.
- Deprecated warning sources were updated: `mesa.drivers` to `mesa`, `pkgs.system` to `pkgs.stdenv.hostPlatform.system`, and `hardware.pulseaudio` to `services.pulseaudio`.
- NixOS writes to `nixpkgs.overlays` that were previously ignored under externally supplied pkgs were removed or limited away from NixOS.

## Why It Matters

The original warning came from providing `pkgs` as a NixOS module special argument. Removing it is required; a control evaluation showed the warning still appears if `specialArgs.pkgs` remains, even with `readOnlyPkgs` imported. Because `readOnlyPkgs` provides module `pkgs` through configuration, platform selection that happens while collecting modules must use `hostSystem` instead of forcing `pkgs`.

## Validation

- `nix eval --impure --json .#hostMetadata`: PASS.
- `nix eval --impure --raw .#nixosConfigurations.axiom.config.system.build.toplevel.drvPath`: PASS, no reported warning strings.
- `nix build --impure --dry-run .#nixosConfigurations.axiom.config.system.build.toplevel`: PASS, no reported warning strings.
- Source checks for exact deprecated warning sources returned no matches.

## Review Result

`docs/review-change.md` records PASS. Security lens was applied because SSH/cloudflared module files were touched; no auth, credential, firewall, or tunnel behavior changes were found.

## Known Limits

- Full all-host NixOS evaluation is blocked by an unrelated existing `godot_4-export-templates` package rename.
- Darwin toplevel evaluation cannot complete on this Linux machine because it needs unavailable `aarch64-darwin` build support.
