{ hey, lib, config, options, ... }:

with lib;
with hey.lib;
let cfg = config.modules.services.calibre;
in {
  options.modules.services.calibre = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.calibre-web = {
      enable = true;

      listen = {
        ip = "0.0.0.0";
      };

      # dataDir = "/home/c1/Books";
      user = "c1";
      group = "users";

      options = {
        # calibreLibrary = /home/c1/Books;
        enableBookUploading = true;
      };

      openFirewall = true;
    };

    # networking.firewall.allowedTCPPorts = [ 8080 ];
  };
}
