# Test Report

## Scope

Validate that the Axiom configuration now owns the GTK3 CSS files that caused the live Thunar contrast regression, while preserving the previous `Breeze-Dark` GTK theme selection.

## Commands

1. `nix eval --option eval-cache false --raw '.#nixosConfigurations.axiom.config.home-manager.users.c1.home.file.".config/gtk-3.0/gtk.css".text'`
   - Result: PASS.
   - Output: `@import "thunar.css";`
   - Reason: verifies the final Home Manager layer will replace the stale live GTK3 CSS entry with a minimal Thunar import.

2. `nix eval --option eval-cache false --raw '.#nixosConfigurations.axiom.config.home-manager.users.c1.home.file.".config/gtk-3.0/thunar.css".text'`
   - Result: PASS.
   - Output includes `.thunar .frame.standard-view`, `background-color: @theme_base_color`, `color: @theme_text_color`, and selected-state use of `@theme_selected_*` colors.
   - Reason: verifies the generated Thunar CSS no longer hard-codes the live light backgrounds (`#f6faf9`, `#eef5f3`) that matched the unreadable screenshot.

3. `nix eval --option eval-cache false --json '.#nixosConfigurations.axiom.config.home-manager.users.c1.home.file.".config/gtk-3.0/gtk.css".force'`
   - Result: PASS, output `true`.
   - Reason: verifies activation is allowed to replace the existing regular `gtk.css` file instead of leaving the stale override in place.

4. `nix eval --option eval-cache false --raw '.#nixosConfigurations.axiom.config.home-manager.users.c1.gtk.theme.name'`
   - Result: PASS, output `Breeze-Dark`.
   - Reason: verifies this regression fix preserves the previous package-level GTK theme decision and only addresses the CSS override.

5. `git diff --check`
   - Result: PASS.
   - Reason: checks whitespace and patch formatting.

6. `nix build --option eval-cache false .#nixosConfigurations.axiom.config.system.build.toplevel --dry-run`
   - Result: PASS.
   - Output lists the new Home Manager file derivations for `.config/gtk-3.0/gtk.css` and `.config/gtk-3.0/thunar.css`, then reports the Axiom toplevel derivations that would be built.
   - Reason: verifies the Axiom NixOS toplevel remains evaluable with the new declarative CSS ownership.

## Warnings

- Nix emitted the existing `specialArgs.pkgs` warning about ignored `nixpkgs.config` and overlay options.
- The toplevel dry-run emitted existing deprecation/rename warnings for `mesa.drivers`, `hardware.pulseaudio`, and `system`.
- These warnings match prior task evidence and are not introduced by this change.

## Skipped

- No live `nixos-rebuild switch` was run, per contract.
- No live Thunar visual smoke was run. After deployment, reopen Thunar in the Axiom graphical session and confirm file labels, sidebar labels, path buttons, and the status bar remain readable.
