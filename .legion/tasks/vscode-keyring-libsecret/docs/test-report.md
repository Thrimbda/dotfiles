# Test Report

## Scope

Validate that the axiom NixOS configuration still evaluates after forcing VS Code to use the GNOME libsecret password store.

## Commands

```bash
nix eval .#nixosConfigurations.axiom.config.system.build.toplevel.drvPath --raw
```

Result: PASS

Returned:

```text
/nix/store/27ifd5918yrl36s90rv6imq7x9z4pk4p-nixos-system-axiom-25.11.20260203.e576e3c.drv
```

Warnings were existing repository/nixpkgs warnings about `specialArgs.pkgs`, deprecated `mesa.drivers`, `system` rename, and `hardware.pulseaudio` rename.

```bash
nix build .#nixosConfigurations.axiom.config.system.build.toplevel --dry-run
```

Result: PASS

The dry-run reports the expected VS Code/package and system derivations that would be built, with no evaluation or build-planning failure.

## Why These Checks

- The change is a Nix package override, so evaluating the axiom top-level derivation proves the option graph and package expression remain valid.
- The dry-run is the strongest low-cost check available here because it confirms Nix can plan the full axiom system build without actually rebuilding or switching the machine.
- Runtime confirmation still requires switching the system profile and restarting VS Code.

## Skipped

- No live VS Code sign-in was attempted in this validation stage. The credential prompt depends on an interactive Electron session and external login flow.
