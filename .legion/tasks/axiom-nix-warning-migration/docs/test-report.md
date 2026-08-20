# Test Report: Axiom Nix Warning Migration

## Scope

Validation covers the Axiom NixOS configuration only. No `switch`, activation, Acorn build, or live suspend was performed.

## Results

| Check | Result | Evidence |
| --- | --- | --- |
| Targeted Bluetooth VM regression | PASS | Built `vm-test-run-bluetooth-predeploy-integration` from Axiom `system.extraDependencies`. The 44-second VM test passed after the boot probe assertion was corrected to inspect the `tlp` node; it proves exactly one boot marker with a valid invocation ID and the post-resume probe ordering. |
| Rendered configuration assertions | PASS | `gtk4Theme = null`, `documentation.info.enable = false`, `services.xserver.enable = false`, `services.resolved.settings.Resolve.DNSSEC = "false"`, `hardware.nvidia.nvidiaSettings = false`, and SSH askpass remains enabled. A separate query confirms `charles` and `charlie` are both `aarch64-darwin`. |
| Shared Colemak consumers | PASS | Atlas and Azar both render as Wayland hosts with `services.xserver.enable = false`, retained `us`/`colemak` XKB values, and SSH askpass enabled. |
| Declared host platforms | PASS | `hostMetadata` lists eight `x86_64-linux` NixOS hosts and only the two intentional `aarch64-darwin` Darwin hosts; no declared host consumes the removed root `x86_64-darwin` platform. |
| Full Axiom build | PASS | After rebasing and correcting the VM assertion, `nixos-rebuild build --flake .#axiom --show-trace -L` completed successfully with no warning output. The system path was generated without collision or Gawk Info-dir warnings. |
| Diff hygiene | PASS | `git diff --check` completed without output. |

## Commands

```sh
nix build --impure --no-link -L --expr 'let cfg = (builtins.getFlake (toString ./.)).nixosConfigurations.axiom.config; matches = builtins.filter (drv: drv.name == "vm-test-run-bluetooth-predeploy-integration") cfg.system.extraDependencies; in builtins.head matches'

nix eval --impure --json --expr 'let f = builtins.getFlake (toString ./.); cfg = f.nixosConfigurations.axiom.config; in { gtk4Theme = cfg.home-manager.users.c1.gtk.gtk4.theme; infoDocs = cfg.documentation.info.enable; xserverEnabled = cfg.services.xserver.enable; sshAskPassword = cfg.programs.ssh.enableAskPassword; dnssec = cfg.services.resolved.settings.Resolve.DNSSEC; nvidiaSettings = cfg.hardware.nvidia.nvidiaSettings; }'

nix eval --impure --json --expr 'let f = builtins.getFlake (toString ./.); names = builtins.attrNames f.darwinConfigurations; in builtins.map (name: { inherit name; system = f.darwinConfigurations.${name}.pkgs.stdenv.hostPlatform.system; }) names'

nix eval --impure --json --expr 'let f = builtins.getFlake (toString ./.); names = [ "atlas" "azar" ]; valueFor = name: let cfg = f.nixosConfigurations.${name}.config; in { desktopType = cfg.modules.desktop.type; xserverEnabled = cfg.services.xserver.enable; xkbLayout = cfg.services.xserver.xkb.layout; xkbVariant = cfg.services.xserver.xkb.variant; sshAskPassword = cfg.programs.ssh.enableAskPassword; }; in builtins.listToAttrs (builtins.map (name: { inherit name; value = valueFor name; }) names)'

nix eval --impure --json .#hostMetadata

nixos-rebuild build --flake .#axiom --show-trace -L

git diff --check
```

## Notes

The first targeted evaluation caught that `systemd.services.*.script` and `preStop` require strings rather than derivations. The fixture now explicitly interpolates the probe path, and the boot probe assertion targets the node that runs the fixture. An earlier cache TLS retry was transient and did not recur in the final build. No switch, activation, Acorn build, or live suspend was performed.
