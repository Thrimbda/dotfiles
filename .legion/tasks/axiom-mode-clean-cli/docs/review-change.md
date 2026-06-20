# Review Change: Axiom Mode Clean CLI

Decision: PASS.

## Findings

No blocking findings.

## Scope Review

- In scope: `packages/axiom-mode/**` adds a standalone Rust package, and `hosts/axiom/default.nix` now installs it through `pkgs.callPackage`.
- In scope: Legion task/wiki docs record the follow-up evidence.
- Out of scope avoided: `axiom-cli.target`, remote access services, Hyprland/greetd wiring, and power policy semantics are unchanged.

## Correctness Review

- The host file no longer embeds command logic in a `writeShellScriptBin` string.
- The Rust CLI preserves the previous command surface: `cli`, `headless`, `tty`, `desktop`, `graphical`, `gui`, `status`, and help aliases.
- `systemctl` is called with fixed argv arrays and fixed target names.
- Nix injects the systemd store path at compile time through `AXIOM_MODE_SYSTEMCTL`, avoiding PATH-dependent command lookup.
- The target and key service relationships evaluated exactly as before.

## Security Lens

Applied because the binary can re-exec through `sudo` and run privileged `systemctl` operations.

No blocking issue found:

- User input only selects a known enum branch.
- Privileged target names are constants, not user-controlled strings.
- The only runtime privilege helper path is `/run/wrappers/bin/sudo`.

## Verification Review

`docs/test-report.md` is sufficient for this refactor. It proves package build, Rust formatting, help output, host package presence, target semantics, removal of the inline script, and Axiom toplevel dry-run.
