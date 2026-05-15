# modules/services/prometheus.nix
#
# For keeping an eye on things...

{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.services.prometheus;
in {
  options.modules.services.prometheus = with types; {
    enable = mkBoolOpt false;
    scrapeConfigs = mkOpt (listOf attrs) [];
  };

  config = mkIf cfg.enable {
    services.prometheus = {
      enable = true;
      scrapeConfigs = cfg.scrapeConfigs;
    };
  };
}
