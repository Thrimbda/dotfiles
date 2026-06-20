# Test Report: Axiom Mode Clean CLI

## Summary

Result: PASS.

This follow-up validates that `axiom-mode` is now a Rust package, the host installs that package, the old inline Bash implementation is gone, and the existing systemd target semantics remain unchanged.

## Commands

### Build the Rust package

```sh
nix build --impure --no-link --print-out-paths .#axiom-mode
```

Evidence: PASS, produced `/nix/store/vaynama4s3nmagr33y3mnag6dcsq13gm-axiom-mode-0.1.0`.

### Check CLI help output

```sh
/nix/store/vaynama4s3nmagr33y3mnag6dcsq13gm-axiom-mode-0.1.0/bin/axiom-mode --help
```

Evidence:

```text
Usage: axiom-mode {cli|desktop|status}

  cli      Persist and switch to SSH-friendly TTY mode.
  desktop  Persist and switch to graphical Hyprland mode.
  status   Show the default target and key unit states.
```

### Check Rust formatting

```sh
nix shell nixpkgs#rustfmt -c rustfmt --check "packages/axiom-mode/src/main.rs"
```

Evidence: PASS after formatting. `nix shell` printed a non-blocking readonly eval-cache warning before running `rustfmt`; `rustfmt --check` reported no remaining diff.

### Evaluate Axiom package and target relationships

```sh
nix eval --impure --json --expr 'let c = (builtins.getFlake (toString ./.)).nixosConfigurations.axiom.config; hasAxiomMode = p: builtins.match ".*axiom-mode.*" (p.name or "") != null; in { hasAxiomMode = builtins.any hasAxiomMode c.environment.systemPackages; axiomModePackages = map (p: p.name or "") (builtins.filter hasAxiomMode c.environment.systemPackages); axiomCli = { after = c.systemd.targets.axiom-cli.after or []; requires = c.systemd.targets.axiom-cli.requires or []; wants = c.systemd.targets.axiom-cli.wants or []; conflicts = c.systemd.targets.axiom-cli.conflicts or []; allowIsolate = c.systemd.targets.axiom-cli.unitConfig.AllowIsolate or null; }; keyWantedBy = { greetd = c.systemd.services.greetd.wantedBy or []; sshd = c.systemd.services.sshd.wantedBy or []; autossh = c.systemd.services.autossh-reverse-ssh.wantedBy or []; cloudflared = c.systemd.services.cloudflared.wantedBy or []; opencode = c.systemd.services.opencode-server.wantedBy or []; }; }'
```

Evidence:

```json
{
  "axiomCli": {
    "after": ["multi-user.target"],
    "allowIsolate": true,
    "conflicts": ["graphical.target"],
    "requires": ["multi-user.target"],
    "wants": ["getty@tty1.service"]
  },
  "axiomModePackages": ["axiom-mode-0.1.0"],
  "hasAxiomMode": true,
  "keyWantedBy": {
    "autossh": ["multi-user.target"],
    "cloudflared": ["multi-user.target"],
    "greetd": ["graphical.target"],
    "opencode": ["multi-user.target"],
    "sshd": ["multi-user.target"]
  }
}
```

### Confirm inline implementation removal

```sh
grep -n 'writeShellScriptBin\s+"axiom-mode"\|pkgs\.writeShellScriptBin\s+"axiom-mode"' hosts/axiom/*.nix
```

Evidence: PASS, no matches.

### Dry-run Axiom system build

```sh
nix build --impure --dry-run .#nixosConfigurations.axiom.config.system.build.toplevel
```

Evidence: PASS, Nix planned the expected Axiom system build without evaluation errors.

## Not Run

- Live `axiom-mode cli` / `desktop` target isolation was not run because this environment is not the live `axiom` host.
