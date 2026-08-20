# One-off Package Module Inventory

## Rule

A module is a one-off package module when its effective behavior is limited to an enable option plus package installation, and it has only one active host consumer. Modules that own services, generated configuration, platform policy, security boundaries or real multi-host reuse are excluded.

This inventory is read-only: it recommends later cleanup but does not delete or inline modules in this task.

## Can Inline

### Sidra

- Module: `modules/desktop/apps/sidra.nix`
- Consumer: `hosts/axiom/default.nix`
- Behavior: selects the Sidra flake package and appends it to `user.packages`.
- Recommendation: place the package directly in Axiom's package list and remove the option module in a later cleanup. Keep the `sidra` flake input while the package is used.

### Laptop utilities

- Module: `modules/profiles/hardware/pc/laptop.nix`
- Consumer: `hosts/ramen/default.nix`
- Behavior: installs `brightnessctl` and `acpi`; the former battery service is commented out.
- Recommendation: place both packages in Ramen. Decide separately whether the `pc/laptop` metadata tag should remain for `hey/info.json` compatibility.

## Unused Package Catalog

These modules have no active host consumer. If the repository is not intended to be a future-feature catalog, deletion is simpler than inventing an inline destination.

| Module | Effective packages | Note |
|---|---|---|
| `modules/shell/adl.nix` | Trackma, anime downloader, mpv, adl | No consumer |
| `modules/dev/clojure.nix` | Clojure, Joker, Leiningen | XDG branch is only a TODO |
| `modules/dev/lua.nix` | Lua, LuaJIT, optional Love2D/Fennel | References stale `devCfg.enableXDG` |
| `modules/dev/scala.nix` | Scala, JDK 17, sbt | Only commented host examples |
| `modules/dev/shell.nix` | ShellCheck | XDG branch is only a TODO |
| `modules/desktop/apps/unity3d.nix` | Unity 3D | No consumer |
| `modules/desktop/apps/ue.nix` | UE4 | No consumer |

## Keep: Multi-host Package Modules

These are package-focused but have current reuse, so inlining would duplicate intent.

| Module | Active consumers | Why keep |
|---|---:|---|
| `modules/dev/cc.nix` | 3 | Shared toolchain and XDG-aware GDB wrapper |
| `modules/dev/deno.nix` | 6 | Cross-platform Linux/Darwin reuse |
| `modules/editors/vscode.nix` | 2 | Shared extension wrapper and password-store policy |
| `modules/desktop/apps/godot.nix` | 2 | Shared Godot/export-template/tooling bundle |
| `modules/system/utils.nix` | 7 | Shared diagnostics baseline |

## Keep: Not Package-only

The following single-host or zero-host modules may deserve a separate dead-code review, but they are not package-only and should not be inlined under this criterion:

- `modules/virt/qemu.nix`: KVM kernel-module policy.
- `modules/virt/libvirt.nix`: groups, libvirtd, swtpm and virt-manager.
- `modules/services/clash-meta.nix`: generated config, service and network capabilities.
- `modules/services/todesk.nix`: state directory, ownership and systemd service.
- `modules/desktop/apps/teamviewer.nix`: wrapper, DBus and daemon integration.
- `modules/virt/lxd.nix`: LXD enablement and image scripts.
- `modules/dev/common-lisp.nix`: generated SBCL configuration.
- `modules/dev/ruby.nix`: aliases and Bundler XDG environment.
- `modules/desktop/term/st.nix`: launcher generation and tmux TERM policy.

## Summary

- Inline candidates: 2.
- Unused package-catalog candidates: 7.
- Package-focused modules justified by active reuse: 5.
- No module is removed by this inventory.
