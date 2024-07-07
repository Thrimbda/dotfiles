# modules/browser/chrome
#
# Chrome that everyone's use.

{ hey, options, config, lib, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop.browsers.chrome;
in {
  options.modules.desktop.browsers.chrome = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      google-chrome
    ];
  };
}
