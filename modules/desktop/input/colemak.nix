{ hey, options, config, lib, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop.input.colemak;
in {
  options.modules.desktop.input.colemak = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.xserver = {
      xkb = {
        layout = "us";
        variant = "colemak";
      };
      enable = true;
    };
    console.useXkbConfig = true;
  };
}
