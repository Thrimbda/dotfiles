# Test Report: Axiom Nix Warning Migration

## Scope

Validation covers the Axiom NixOS configuration only. No `switch`, activation, Acorn build, or live suspend was performed.

## Results

| Check | Result | Evidence |
| --- | --- | --- |
| Targeted Bluetooth VM regression | PASS | Built `vm-test-run-bluetooth-predeploy-integration` from Axiom `system.extraDependencies`; the 52-second VM test passed both normal and failing TLP resume paths, including the new boot and post-resume probe ordering. |
| Rendered configuration assertions | PASS | `gtk4Theme = null`, `documentation.info.enable = false`, `services.xserver.enable = false`, Colemak XKB remains `us`/`colemak`, and SSH askpass remains enabled. |
| Deprecated source references | PASS | Targeted search found no active references to the warned aliases, options, or `powerManagement.powerUpCommands`. |
| Full Axiom build | PASS | `nixos-rebuild build --flake .#axiom --show-trace -L` completed successfully with no warning output. The system path was generated without collision or Gawk Info-dir warnings. |
| Diff hygiene | PASS | `git diff --check` completed without output. |

## Commands

```sh
nix build --impure --no-link -L --expr 'let cfg = (builtins.getFlake (toString ./.)).nixosConfigurations.axiom.config; matches = builtins.filter (drv: drv.name == "vm-test-run-bluetooth-predeploy-integration") cfg.system.extraDependencies; in builtins.head matches'

nix eval --impure --json --expr 'let cfg = (builtins.getFlake (toString ./.)).nixosConfigurations.axiom.config; in { infoDocs = cfg.documentation.info.enable; gtk4Theme = cfg.home-manager.users.c1.gtk.gtk4.theme; xserverEnabled = cfg.services.xserver.enable; sshAskPassword = cfg.programs.ssh.enableAskPassword; }'

nixos-rebuild build --flake .#axiom --show-trace -L

git diff --check
```

## Notes

The first targeted evaluation caught that `systemd.services.*.script` and `preStop` require strings rather than derivations. The fixture now explicitly interpolates the probe path; the subsequent VM regression and full build pass. An earlier cache TLS retry was transient and did not recur in the final build.
