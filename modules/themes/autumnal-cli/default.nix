# modules/themes/autumnal-cli/default.nix --- CLI-only slice of the autumnal theme

{ hey, heyBin, lib, config, pkgs, ... } @ args:

with lib;
with hey.lib;
let
  cfg = config.modules.theme;
in mkIf (cfg.active == "autumnal-cli") {
  modules = {
    shell.zsh.rcFiles  = [ ./config/zsh/prompt.zsh ];
    shell.tmux.rcFiles = [ ./config/tmux.conf ];
  };
}
