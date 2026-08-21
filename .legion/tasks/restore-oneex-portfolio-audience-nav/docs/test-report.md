# Deployment Attempt Report

## Result

The original deployment was blocked before build. A follow-up fresh-derivation build successfully compiled and tested the adapter, but the full system build exceeded the agent execution window before transfer or Acorn activation.

## Intended Command

```sh
nixos-rebuild switch --flake .#acorn --target-host c1@8.159.128.125 --build-host localhost --sudo --ask-sudo-password --use-substitutes -L
```

The command ran from the clean task worktree on Axiom. Acorn was only the target host; no build was attempted on Acorn.

## Initial Failure

Nix evaluation of the current `origin/master` configuration stopped with these assertions:

```text
Can't enable a desktop sub-module without a desktop environment
Downstream desktop module did not set modules.desktop.type
```

The failure occurred while evaluating `system.build.toplevel`, before any closure was built, copied, or activated.

## Fresh Derivation Build

The prior adapter output was registered and live in Axiom's local Nix store database but absent from disk. Store repair was unsupported by the daemon, and normal deletion correctly refused to remove a live path. The adapter package version suffix was therefore changed to create a fresh Nix output from the unchanged vendor source.

The prescribed Axiom build then completed these adapter-specific checks successfully:

```text
fresh_adapter_output=/nix/store/jrvqblngc25j2xfqlbvbn25804ikd0y9-oneex-portfolio-adapter-0.1.0-8dcf21f-audience-rebuild1
cargo_release_build=passed
adapter_unit_tests=10 passed, 0 failed
```

The full system closure was still building when the noninteractive execution window expired. It was interrupted before any closure transfer or remote activation.

## Impact

- The running Acorn adapter remains unchanged; the fresh output has not yet been copied or activated.
- No Custom Account Source, Fund configuration, investor, cash flow, unit, or NAV event was written during this task.
- The approved Fund initialization must remain blocked because a safe post-write sample is impossible while the source returns `502`.

## Recovery Condition

Merge the fresh-derivation configuration change, then rerun the prescribed Axiom-to-Acorn deployment command from a persistent interactive terminal on the merged `master` baseline. Only after successful source and immediate Fund-sample preflight may the guarded owner initialization continue.
