# Axiom CLI Mode

## Goal

Add a host-local, one-command mode switch for `axiom` so it can run as an SSH-accessible workstation without starting the Hyprland desktop when the machine is only being used remotely.

## Problem

`axiom` is configured as a graphical NixOS workstation, but there are periods where it is only accessed through SSH. In those periods the graphical session is unnecessary and keeps extra desktop processes, compositor state, and display activity alive. The host needs a simple way to persistently switch between desktop mode and a lean CLI mode while preserving remote access.

## Acceptance

- `axiom-mode cli` switches the system to a persistent non-graphical mode immediately.
- `axiom-mode desktop` switches the system back to the persistent graphical default immediately.
- `axiom-mode status` reports the default target and key service states without requiring root.
- CLI mode preserves `sshd`, reverse SSH, cloudflared, and opencode services because they remain under `multi-user.target`.
- A local display in CLI mode exposes a raw TTY login path rather than starting Hyprland.
- The implementation does not depend on `hey`, `hey` hooks, or `hey` runtime commands.

## Assumptions

- NixOS systemd targets are the right abstraction for switching between graphical and non-graphical runtime modes.
- `greetd` remains tied to `graphical.target` and remote access services remain tied to `multi-user.target`.
- The user prefers a host-local command over maintaining separate NixOS host configurations or specialisations for this low-risk toggle.

## Constraints

- Keep the change scoped to `axiom`.
- Do not rework the Hyprland, greetd, SSH, reverse SSH, cloudflared, or opencode modules.
- Do not introduce a dependency on `hey` for this command.
- Avoid touching unrelated in-flight work in the main workspace.

## Risks

- Isolating a systemd target can terminate active graphical user processes immediately.
- If tty1 is owned by the display manager by default, CLI mode must explicitly request a getty for local-console fallback.
- Actual power savings depend on NVIDIA idle behavior and attached display state; this task only creates the operational mode switch.

## Scope

- Add an `axiom-mode` system command to `axiom`.
- Add an `axiom-cli.target` that requires `multi-user.target`, wants `getty@tty1.service`, and conflicts with `graphical.target`.
- Document the mode switch in `hosts/axiom/README.org`.
- Verify the evaluated systemd relationships and generated script syntax.

## Non-Goals

- Do not implement deep NVIDIA runtime power management changes.
- Do not tune CPU governor, suspend behavior, fan curves, or monitor DDC power controls.
- Do not create a second NixOS host or boot specialisation.
- Do not change remote access topology.

## Design Summary

The recommended path is a small systemd-target wrapper. `axiom-mode cli` sets the default target to `axiom-cli.target` and isolates it. `axiom-mode desktop` sets the default target to `graphical.target` and isolates it. The custom CLI target makes the desired non-graphical mode explicit while still leaning on NixOS/systemd defaults for service lifecycle.

## Phases

- Materialize this task contract and keep scope limited to the mode switch.
- Implement the host-local target and standalone command.
- Verify NixOS evaluation, generated script syntax, and target/service relationships.
- Review the final diff for accidental unrelated changes.
- Write handoff and wiki evidence for future maintenance.
