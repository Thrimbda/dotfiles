# modules/browser/edge
#
# I am addicted to the feature of virtical tabs

{ hey, options, config, lib, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop.browsers.edge;
in {
  options.modules.desktop.browsers.edge = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      microsoft-edge
    ];
  };
}
