# RFC: Axiom Nix Warning Migration

## Context

`nixos-rebuild build --flake .#axiom --show-trace -L` currently succeeds but emits two classes of deterministic, repository-owned diagnostics:

- Deprecated Nixpkgs package aliases, NixOS options, Home Manager defaults, and the root `x86_64-darwin` output platform.
- `pkgs.buildEnv` collisions caused by two providers for SSH tools, X11 utilities, Steam, Gamescope, and NVIDIA Settings.

The same build can also show transient cache TLS retry messages and an upstream Gawk `gawknotes.info` direntry warning. Cache retries remain external. The user explicitly chose to disable Linux system Info documentation, which matches the repository's existing disabled-documentation posture and removes the Gawk diagnostic without carrying a package patch.

All declared Darwin hosts are `aarch64-darwin`; root host discovery has no `x86_64-darwin` consumer. The separate Acorn image flake is outside this task's root platform set.

## Options

### 1. Source-level migrations and single package ownership

Replace every deprecated reference with its documented successor, make the selected GTK4 behavior explicit, remove the unused root output platform, and remove duplicate package providers while retaining their wrapped behavior.

### 2. Suppress warnings or globally adjust package priority

Hide evaluation diagnostics or force a broad package priority. This keeps scheduled removals and ambiguous binary ownership in place, so it is rejected.

### 3. Remove affected features

Disable GTK configuration, XWayland utilities, Steam, NVIDIA Settings, or cache use. This is rejected because it trades working behavior for quieter logs. Disabling system Info documentation is the explicit, narrowly chosen exception.

## Decision

Choose option 1.

- Remove only `x86_64-darwin` from the root `systems` list. Retain the generic Intel-Darwin fallback code and the separate image flake because they are not evaluated by the Axiom root build.
- Set `modules.theme.gtk.gtk4.theme = null`. This is the user-selected Home Manager default. GTK3 Thunar CSS, GTK icon/cursor configuration, and dark preferences remain configured.
- Use top-level replacements for renamed packages and aliases: `antigravity-ide-fhs`, `xrandr`, `xorg-server`, the top-level X11 libraries, `thunar-archive-plugin`, `thunar-volman`, and `glew_1_10`.
- Move both DNSSEC definitions to `services.resolved.settings.Resolve.DNSSEC`, and move display-manager variables to `services.displayManager.generic.environment`.
- Set Linux `documentation.info.enable` to `false` by default. This explicitly opts out of system Info pages and eliminates the upstream Gawk direntry warning; an override can re-enable them later.
- Replace the Bluetooth VM test's deprecated `powerUpCommands` with two explicit fixtures:
  - A boot oneshot wanted by `multi-user.target` runs the probe once after boot.
  - A `sleep.target` oneshot starts before sleep and runs its probe in `ExecStop` after `sleep-actions` and `tlp-sleep` stop on resume. This retains the fixture's observable ordering without changing production Bluetooth resume logic.
- Normalize system-path ownership:
  - Use one wrapped OpenSSH package via `programs.ssh.package`, wrapping `ssh`, `scp`, `ssh-add`, and `ssh-copy-id` in that same package.
  - Keep Colemak XKB settings for Hyprland and the console, enable a full Xorg server only when a host declares an X11 desktop type, and explicitly retain SSH askpass for Colemak desktop sessions. This removes Axiom's redundant Xorg server while preserving the prior askpass default and leaving X11 hosts able to opt in.
  - Retain the wrapped Steam package at higher priority than the module's base package, remove the redundant raw Gamescope package, and retain the NixOS Gamescope wrapper.
  - Disable NixOS's automatic raw NVIDIA Settings package while retaining the existing XDG-aware wrapper.

## Rollback

All changes are declarative and reversible with `git revert`. No persisted data or service state is migrated. If an application loses an expected wrapper behavior, restore only its previous package owner or wrapper, rather than reintroducing a broad collision. A host can override the default to restore system Info pages.

## Verification

- Run the targeted Bluetooth VM test to prove boot and resume probe ordering after the explicit service migration.
- Evaluate the Axiom configuration to confirm the selected GTK4 value, supported Darwin output set, NixOS option values, intended package ownership, disabled full Xorg server, retained XKB values, and retained SSH askpass setting.
- Run `nixos-rebuild build --flake .#axiom --show-trace -L` without deploying.
- Confirm that evaluation warnings, `pkgs.buildEnv` collision warnings, and the Gawk Info warning from the baseline are absent. Record any cache TLS retries separately as transient network evidence.
