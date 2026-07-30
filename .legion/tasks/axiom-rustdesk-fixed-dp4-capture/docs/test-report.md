# Verification Report: Persistent unattended DP-4 capture

## Result

Static verification passed. Runtime acceptance is pending deployment from the
merged baseline and a remote RustDesk connection.

## Passed

| Check | Evidence | Result |
| --- | --- | --- |
| Nix evaluation | `nix eval --impure --raw .#nixosConfigurations.axiom.config.systemd.services.rustdesk.serviceConfig.ExecStartPre` | Returned the generated `axiom-rustdesk-state-access` script. |
| Service invariants | Evaluated `rustdesk.service.serviceConfig` | `ExecStart` remains `rustdesk --service`; `User=root`; only `ExecStartPre` was added. |
| Runtime environment | Evaluated `rustdesk.service.environment` | `HOME=/root` and `XDG_CONFIG_HOME=/root/.config` are unchanged. |
| Restart wiring | Evaluated `rustdesk.service.restartTriggers` | Includes only the new state-access script for this change. |
| Full configuration build | `nix build --no-link --impure --log-format bar .#nixosConfigurations.axiom.config.system.build.toplevel` | Passed on Axiom. The resulting toplevel is `/nix/store/d5rf0k1qzchw9s9c895zlr3rdymdnxi0-nixos-system-axiom-25.11.20260630.b6018f8`. |
| Generated script | `bash -n /nix/store/zyrn7rzzrwn8fhxwzzhd2ca38ld3hdqx-axiom-rustdesk-state-access` | Passed. Generated commands use immutable coreutils and ACL paths. |
| Generated unit | Read the built `rustdesk.service` | Contains `ExecStartPre` and unchanged root environment, start command, stop command, and limits. |
| Diff hygiene | `git diff --check` | Passed. |

The first full build emitted only existing xorg deprecation warnings. A transient
Hyprland Cachix TLS warning occurred before retry; the subsequent full build
completed successfully.

## Pending Runtime Acceptance

Production activation must happen only after the PR is merged and the main
worktree is refreshed. Then verify:

1. `rustdesk.service` starts successfully and its pre-start script leaves
   `RustDesk.toml` root-owned while `RustDesk2.toml` is owned by c1.
2. A new remote connection selects DP-4 without an Axiom-side chooser.
3. After restarting RustDesk, a second new connection restores DP-4 without
   interaction and the Wayland restore token remains present.

These checks require a privileged system switch and a remote RustDesk client,
so they cannot be truthfully claimed from the build-only worktree.
