# SSH Foot Term Compatibility Test Report

## Summary

PASS. The change builds the repository-managed Axiom OpenSSH wrapper with `export TERM='xterm-256color'` in `bin/ssh`, while leaving the sibling `bin/scp` wrapper without a `TERM` override. Targeted host option evaluation passes for the Foot-based hosts checked, and diff whitespace validation passes.

## Commands

### Diff Whitespace

Command:

```bash
git diff --check
```

Result: PASS, no output.

Why this matters: catches malformed patch whitespace before commit/PR.

### Axiom SSH Wrapper Enablement

Command:

```bash
nix eval --impure --expr '(builtins.getFlake (toString ./.)).nixosConfigurations.axiom.config.modules.xdg.ssh.enable'
```

Result: PASS, returned `true`.

Why this matters: confirms the host that uses Foot also enables the repository-managed SSH wrapper receiving the fix.

### Azar SSH Wrapper Enablement

Command:

```bash
nix eval --impure --expr '(builtins.getFlake (toString ./.)).nixosConfigurations.azar.config.modules.xdg.ssh.enable'
```

Result: PASS, returned `true`.

Why this matters: checks the second Foot-enabled host also uses the same SSH wrapper path.

### Generated Axiom OpenSSH Wrapper

Command:

```bash
nix build --impure --no-link --print-out-paths --expr 'let flake = builtins.getFlake (toString ./.); cfg = flake.nixosConfigurations.axiom.config; wrappers = builtins.filter (p: builtins.match ".*openssh.*wrapped" (p.name or "") != null) cfg.environment.systemPackages; in builtins.head wrappers'
```

Result: PASS, built `/nix/store/aiszvjysfr8zvfwwlkxg76g41hand9v9--nix-store-9ng738k8rbl6n6yz0x20kxnfxzhlns0c-openssh-10.2p1-wrapped`.

Evidence from generated `bin/ssh`:

```bash
export TERM='xterm-256color'
```

Evidence from generated `bin/scp`: no `TERM` override is present.

Why this matters: directly validates the generated wrapper behavior instead of only checking source text.

## Warnings

- Nix evaluation emitted the existing `specialArgs.pkgs` warning.
- The wrapper build emitted existing `mesa.drivers` deprecation warnings.
- These warnings are unrelated to the SSH `TERM` compatibility change and did not fail validation.

## Not Run

- Live SSH to an affected remote host was not run from this tool session; the generated wrapper inspection proves the local side will no longer send `TERM=foot` when using the managed `ssh` binary after deployment.
