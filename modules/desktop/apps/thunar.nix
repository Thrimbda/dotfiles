# modules/desktop/apps/thunar.nix --- TODO
#
# TODO

{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let
  cfg = config.modules.desktop.apps.thunar;
  gtkCss = ''
    @import "thunar.css";
  '';
  thunarCss = ''
    /* Keep stale/generated GTK CSS from forcing light Thunar surfaces over a dark theme. */
    .thunar.background {
      background-color: @theme_bg_color;
      color: @theme_fg_color;
    }

    .thunar .frame.standard-view {
      background-color: @theme_base_color;
      color: @theme_text_color;
      border-radius: 15px;
    }

    .thunar .frame.standard-view .view,
    .thunar .frame.standard-view .view *:not(:selected):not(.rubberband) {
      background-color: transparent;
      color: @theme_text_color;
    }

    .thunar .sidebar,
    .thunar .sidebar .view {
      background-color: transparent;
      color: @theme_fg_color;
    }

    .thunar .location-button.path-bar-button:not(:checked),
    .thunar statusbar {
      background-color: @theme_base_color;
      color: @theme_text_color;
    }

    .thunar .frame.standard-view .view *:selected,
    .thunar .sidebar .view:selected,
    .thunar .location-button.toggle:checked,
    .thunar .path-bar-button.toggle:checked {
      background-color: @theme_selected_bg_color;
      color: @theme_selected_fg_color;
    }

    .thunar .rubberband {
      background-color: alpha(@theme_selected_bg_color, 0.35);
      border: 1px solid @theme_selected_bg_color;
    }
  '';
in {
  options.modules.desktop.apps.thunar = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    programs.thunar.enable = true;
    programs.thunar.plugins = with pkgs.xfce; [
      thunar-archive-plugin
      thunar-volman
    ];
    services.gvfs.enable = true; # Mount, trash, and other Finder-like functionality.
    services.tumbler.enable = true; # Thumbnail support for images

    home.configFile = {
      "gtk-3.0/gtk.css" = {
        force = true;
        text = gtkCss;
      };
      "gtk-3.0/thunar.css" = {
        force = true;
        text = thunarCss;
      };
    };
  };
}
