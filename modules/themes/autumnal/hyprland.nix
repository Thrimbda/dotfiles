{ hey, heyBin, lib, config, pkgs, ... } @ args:

with lib;
with hey.lib;
let cfg = config.modules.theme;
in mkIf (cfg.active == "autumnal") {
  modules.desktop.hyprland.extraConfig = ''
    hl.env("HYPRCURSOR_THEME", "${cfg.gtk.cursorTheme.name}")
    hl.env("HYPRCURSOR_SIZE", "${toString cfg.gtk.cursorTheme.size}")

    hl.config({
      general = {
        gaps_in = 5,
        gaps_out = 10,
        border_size = 1,
        col = {
          active_border = { colors = { "rgba(f5c2e7ff)", "rgba(89b4faff)" }, angle = 45 },
          inactive_border = "rgba(45475aff)",
        },
      },
      decoration = {
        rounding = 15,
        active_opacity = 0.95,
        inactive_opacity = 0.95,
        fullscreen_opacity = 1.0,
        dim_strength = 0.12,
        dim_inactive = false,
        dim_special = 0.28,
        dim_around = 0.28,
        shadow = {
          enabled = true,
          range = 20,
          render_power = 3,
          color = "rgba(11111bcc)",
          color_inactive = "rgba(11111b44)",
        },
        blur = {
          enabled = true,
          size = 8,
          passes = 2,
          ignore_opacity = true,
          xray = false,
        },
      },
    })

    -- Caelestia owns desktop chrome; keep only compositor-level polish here.
    hl.layer_rule({ name = "caelestia-blur", match = { namespace = "caelestia.*" }, blur = true })
    hl.layer_rule({ name = "caelestia-alpha", match = { namespace = "caelestia.*" }, ignore_alpha = 0 })
  '';

  home.configFile."doom/config.local.el".text = ''
    ;; -*- lexical-binding: t -*-
    (add-to-list 'default-frame-alist '(alpha-background . 95))
    (setq doom-theme 'doom-tomorrow-night)
    (custom-theme-set-faces! 'doom-tomorrow-night
      '(default :background "#1d1f21")
      '(solaire-default-face :background "#191B1A"))
  '';
}
