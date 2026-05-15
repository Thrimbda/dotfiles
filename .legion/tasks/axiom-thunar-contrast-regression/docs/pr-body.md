## Summary

- Fix the Thunar contrast regression by declaratively owning GTK3 `gtk.css`/`thunar.css` instead of relying only on the `Breeze-Dark` theme selection.
- Replace stale light Thunar CSS surfaces with Thunar-scoped rules using GTK theme color variables.
- Add Legion regression evidence, verification report, and review handoff.

## Verification

- `nix eval --option eval-cache false --raw '.#nixosConfigurations.axiom.config.home-manager.users.c1.home.file.".config/gtk-3.0/gtk.css".text'`
- `nix eval --option eval-cache false --raw '.#nixosConfigurations.axiom.config.home-manager.users.c1.home.file.".config/gtk-3.0/thunar.css".text'`
- `nix eval --option eval-cache false --json '.#nixosConfigurations.axiom.config.home-manager.users.c1.home.file.".config/gtk-3.0/gtk.css".force'`
- `nix eval --option eval-cache false --raw '.#nixosConfigurations.axiom.config.home-manager.users.c1.gtk.theme.name'`
- `git diff --check`
- `nix build --option eval-cache false .#nixosConfigurations.axiom.config.system.build.toplevel --dry-run`

## Notes

- No live switch was run. After deployment, reopen Thunar to confirm perceived contrast.
