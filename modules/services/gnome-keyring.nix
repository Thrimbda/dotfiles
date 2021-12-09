{ options, config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.services.gnome-keyring;
    configDir = config.dotfiles.configDir;
in {
  options.modules.services.gnome-keyring = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.gnome.gnome-keyring.enable = true;
    # security.pam.services.login.enableGnomeKeyring = true;
  };
}
