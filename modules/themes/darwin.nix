{ hey, lib, config, pkgs, ... }:

with lib;
let
  cfg = config.modules.theme or {};
  themeName = cfg.active or null;
  themeDir = "${hey.themesDir}/${toString themeName}";
  hasPrompt = themeName != null && builtins.pathExists "${themeDir}/config/zsh/prompt.zsh";
  hasTmux = themeName != null && builtins.pathExists "${themeDir}/config/tmux.conf";
  promptFile =
    if hasPrompt
    then pkgs.writeText "theme-${themeName}-prompt.zsh" (builtins.readFile "${themeDir}/config/zsh/prompt.zsh")
    else null;
  tmuxFile =
    if hasTmux
    then pkgs.writeText "theme-${themeName}-tmux.conf" (builtins.readFile "${themeDir}/config/tmux.conf")
    else null;
in {
  options.modules.theme.active = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = "Active CLI theme.";
  };

  config = mkIf (themeName != null) {
    hey.info.theme = { active = themeName; };

    modules.shell.zsh = optionalAttrs hasPrompt {
      rcFiles = [ "${promptFile}" ];
    };

    modules.shell.tmux = optionalAttrs hasTmux {
      rcFiles = [ "${tmuxFile}" ];
    };
  };
}
