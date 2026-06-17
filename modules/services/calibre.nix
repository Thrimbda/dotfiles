{ hey, lib, config, options, ... }:

with lib;
with hey.lib;
let cfg = config.modules.services.calibre;
in {
  options.modules.services.calibre = with types; {
    enable = mkBoolOpt false;
    user = mkOpt str config.user.name;
    group = mkOpt str (config.user.group or "users");
  };

  config = mkIf cfg.enable {
    services.calibre-web = {
      enable = true;

      listen = {
        ip = "0.0.0.0";
      };

      user = cfg.user;
      group = cfg.group;

      options = {
        enableBookUploading = true;
      };

      openFirewall = true;
    };

    # networking.firewall.allowedTCPPorts = [ 8080 ];
  };
}
