{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.services.mihomo;
    configDir = config.user.home + "/.config/mihomo";
in {
  options.modules.services.mihomo = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.mihomo = {
      enable = true;
      configFile = "${configDir}/config.toml";
      tunMode = true;
    };
  };
}
