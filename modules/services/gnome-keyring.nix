{ options, config, lib, pkgs, hey, ... }:

with lib;
with hey.lib;
let cfg = config.modules.services.gnome-keyring;
    configDir = config.dotfiles.configDir;
in {
  options.modules.services.gnome-keyring = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.lightdm.enableGnomeKeyring = true;
    user.packages = with pkgs; [
      gnome.seahorse
    ];
  };
}
