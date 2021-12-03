{ config, options, pkgs, lib, ... }:

with lib;
with lib.my;
let cfg = config.modules.services.onedrive;
in {
  options.modules.services.onedrive = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.onedrive = rec {
      enable = true;
    };
  };
}
