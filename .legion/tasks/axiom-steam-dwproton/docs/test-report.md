# Test Report

## Summary

PASS. The change evaluates as opt-in, enables DWProton only for Axiom, leaves a representative non-DWProton Steam host unchanged, builds the selected DWProton package, builds the Axiom NixOS toplevel, and passes whitespace checks.

## Commands

### Axiom option enablement

Command:

```sh
nix eval --json '.#nixosConfigurations.axiom.config.modules.desktop.apps.steam.dwproton.enable'
```

Result: PASS

Output:

```text
true
```

Why: proves the Axiom host config enables the new opt-in option.

### Axiom Steam compatibility package list

Command:

```sh
nix eval --json '.#nixosConfigurations.axiom.config.programs.steam.extraCompatPackages' --apply 'packages: map (package: package.name or package.pname or "unknown") packages'
```

Result: PASS

Output:

```text
["dwproton-11.0-4"]
```

Note: Nix emitted an ignored eval-cache SQLite busy warning during this run. The command still completed successfully and returned the expected package list.

Why: proves the enabled option wires DWProton into `programs.steam.extraCompatPackages`.

### Representative default host option

Command:

```sh
nix eval --json '.#nixosConfigurations.azar.config.modules.desktop.apps.steam.dwproton.enable'
```

Result: PASS

Output:

```text
false
```

Why: proves a Steam host that does not opt in keeps the default disabled value.

### Representative default host compatibility package list

Command:

```sh
nix eval --json '.#nixosConfigurations.azar.config.programs.steam.extraCompatPackages' --apply 'packages: map (package: package.name or package.pname or "unknown") packages'
```

Result: PASS

Output:

```text
[]
```

Note: Nix emitted an ignored eval-cache SQLite busy warning during this run. The command still completed successfully and returned an empty list.

Why: proves non-opt-in Steam configuration does not receive DWProton.

### Selected DWProton package build

Command:

```sh
nix build --impure --no-link --print-out-paths --expr 'let flake = builtins.getFlake "path:/home/c1/dotfiles/.worktrees/axiom-steam-dwproton"; in builtins.elemAt flake.nixosConfigurations.axiom.config.programs.steam.extraCompatPackages 0'
```

Result: PASS

Output:

```text
/nix/store/rynhdf4br2rqb4dx3hifa3hwfgy7grci-dwproton-11.0-4
```

Why: proves the exact package selected through Axiom's Steam configuration builds.

Note: `--impure` is only needed because this validates a dirty local path flake before commit. The package itself comes from the locked `dwproton` input.

### Axiom NixOS toplevel build

Command:

```sh
nix build --no-link --print-out-paths '.#nixosConfigurations.axiom.config.system.build.toplevel'
```

Result: PASS

Output:

```text
/nix/store/hrpwjpm0p8m8p2h9cbi65fk1gl4gvmps-nixos-system-axiom-25.11.20260203.e576e3c
```

Why: proves the host configuration containing the new Steam compatibility package still builds.

### Whitespace check

Command:

```sh
git diff --check
```

Result: PASS

Output: no output.

Why: catches common whitespace mistakes before commit.

## Non-blocking Notes

- `nix flake lock --update-input dwproton` hit GitHub's unauthenticated API rate limit and used Nix's cached version. The resulting lock entry matches the expected upstream revision `70f6c85a85337e4b4030937f3963142ae232dc23` with nar hash `sha256-Z7hBU8Vc0j0XxUNFHEA1wdtzcAtGx+nJwFaskiQ5rok=`.
- A live Steam UI check is intentionally deferred until after `hey sync --host axiom switch` and Steam restart, per the task non-goals.
