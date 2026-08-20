# Deployment Attempt Report

## Result

BLOCKED before build, transfer, or Acorn activation.

## Intended Command

```sh
nixos-rebuild switch --flake .#acorn --target-host c1@8.159.128.125 --build-host localhost --sudo --ask-sudo-password --use-substitutes -L
```

The command ran from the clean task worktree on Axiom. Acorn was only the target host; no build was attempted on Acorn.

## Failure

Nix evaluation of the current `origin/master` configuration stopped with these assertions:

```text
Can't enable a desktop sub-module without a desktop environment
Downstream desktop module did not set modules.desktop.type
```

The failure occurred while evaluating `system.build.toplevel`, before any closure was built, copied, or activated.

## Impact

- The running Acorn adapter remains on the old binary that lacks `redirect_uri` and its source positions path still returns `502`.
- No Custom Account Source, Fund configuration, investor, cash flow, unit, or NAV event was written during this task.
- The approved Fund initialization must remain blocked because a safe post-write sample is impossible while the source returns `502`.

## Recovery Condition

Resolve the unrelated desktop-module assertions in the dotfiles baseline, then rerun the prescribed Axiom-to-Acorn deployment command from a clean worktree. Only after successful source and immediate Fund-sample preflight may the guarded owner initialization continue.
