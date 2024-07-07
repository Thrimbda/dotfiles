{ hey, options, config, lib, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop.input.fcitx5-rime;
    configDir = config.dotfiles.configDir;
in {
  options.modules.desktop.input.fcitx5-rime = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    i18n.inputMethod.enabled =  "fcitx5";
    i18n.inputMethod.fcitx5.addons = with pkgs; [
      fcitx5-rime
    ];

    # TODO: make rime config
    # home.dataFile = {

    # };
  };
}
