# Test Report: Axiom CLI Mode

## Summary

Result: PASS.

The validation focused on the exact claims of this change: `axiom-mode` is present in the system profile, `axiom-cli.target` has the intended target relationships, graphical login remains tied to `graphical.target`, and remote access services remain tied to `multi-user.target`.

## Commands

### Evaluate generated NixOS config

```sh
nix eval --impure --json --expr 'let c = (builtins.getFlake (toString ./.)).nixosConfigurations.axiom.config; hasAxiomMode = p: builtins.match ".*axiom-mode.*" (p.name or "") != null; in { defaultTarget = c.systemd.defaultUnit; hasAxiomMode = builtins.any hasAxiomMode c.environment.systemPackages; axiomCli = { after = c.systemd.targets.axiom-cli.after or []; requires = c.systemd.targets.axiom-cli.requires or []; wants = c.systemd.targets.axiom-cli.wants or []; conflicts = c.systemd.targets.axiom-cli.conflicts or []; allowIsolate = c.systemd.targets.axiom-cli.unitConfig.AllowIsolate or null; }; keyWantedBy = { greetd = c.systemd.services.greetd.wantedBy or []; sshd = c.systemd.services.sshd.wantedBy or []; autossh = c.systemd.services.autossh-reverse-ssh.wantedBy or []; cloudflared = c.systemd.services.cloudflared.wantedBy or []; opencode = c.systemd.services.opencode-server.wantedBy or []; }; }'
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
  "defaultTarget": "graphical.target",
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

### Build and syntax-check generated command

```sh
pkg=$(nix build --impure --no-link --print-out-paths --expr 'let c = (builtins.getFlake (toString ./.)).nixosConfigurations.axiom.config; matches = builtins.filter (p: builtins.match ".*axiom-mode.*" (p.name or "") != null) c.environment.systemPackages; in builtins.head matches') && bash -n "$pkg/bin/axiom-mode" && "$pkg/bin/axiom-mode" --help
```

Evidence:

```text
Usage: axiom-mode {cli|desktop|status}

  cli      Persist and switch to SSH-friendly TTY mode.
  desktop  Persist and switch to graphical Hyprland mode.
  status   Show the default target and key unit states.
```

### Dry-run full Axiom system build

```sh
nix build --impure --dry-run .#nixosConfigurations.axiom.config.system.build.toplevel
```

Evidence: PASS. Nix planned the expected derivations, including `unit-axiom-cli.target.drv`, without evaluation errors.

## Why These Checks

- The targeted eval proves the systemd target and service attachment semantics that make CLI mode safe for SSH-only use.
- The command build plus `bash -n` proves the generated standalone script is syntactically valid and available without `hey`.
- The system dry-run proves the host-level NixOS configuration still composes.

## Not Run

- Runtime `systemctl isolate axiom-cli.target` was not executed because this environment is not the live `axiom` host.
- NVIDIA power draw measurements were not run because this task only adds the mode switch; live power validation should happen after deployment on `axiom`.
