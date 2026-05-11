# Test Report: Install ToDesk on axiom

Date: 2026-05-11

## Summary

PASS. The pinned nixpkgs input exposes `pkgs.todesk` for `x86_64-linux`, and the axiom NixOS configuration evaluates with ToDesk present in `config.user.packages`.

## Commands

### Package metadata

Command:

```sh
nix eval --json --impure --expr 'let flake = builtins.getFlake (toString ./.); pkgs = import flake.inputs.nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; }; in { name = pkgs.todesk.name; broken = pkgs.todesk.meta.broken or false; platforms = pkgs.todesk.meta.platforms or []; mainProgram = pkgs.todesk.meta.mainProgram or null; }'
```

Result:

```json
{"broken":false,"mainProgram":"todesk","name":"todesk-4.7.2.0","platforms":["x86_64-linux"]}
```

Why this command: it directly verifies the package name used by the implementation exists in the pinned nixpkgs input and is valid for axiom's platform.

### Axiom configuration evaluation

Command:

```sh
nix eval --json --impure --expr 'let flake = builtins.getFlake (toString ./.); cfg = flake.nixosConfigurations.axiom.config; in { hasTodesk = builtins.any (pkg: (pkg.pname or (pkg.name or "")) == "todesk") cfg.user.packages; toplevelDrv = cfg.system.build.toplevel.drvPath; }'
```

Result:

```json
{"hasTodesk":true,"toplevelDrv":"/nix/store/7z47gsmvmaf8ng1dg7i8scnryqjaq582-nixos-system-axiom-25.11.20260203.e576e3c.drv"}
```

The evaluation emitted existing repository warnings about `specialArgs.pkgs`, deprecated `mesa.drivers`, renamed `hardware.pulseaudio`, and renamed `system`; none are introduced by this package-only change.

Why this command: it evaluates the host configuration and checks the exact claim that axiom's user package list now contains `todesk`, without switching the live system.

## Skipped

- `nixos-rebuild switch`: skipped by explicit task constraint.
- Full system build: not required for this low-risk package declaration; host evaluation to a toplevel derivation provides the targeted evidence needed for this change.

## Residual Risk

- Runtime behavior of the proprietary ToDesk application was not exercised. This task only proves declarative package inclusion and Nix evaluation.
