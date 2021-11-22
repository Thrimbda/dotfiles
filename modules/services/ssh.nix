{ options, config, lib, ... }:

with lib;
with lib.my;
let cfg = config.modules.services.ssh;
in {
  options.modules.services.ssh = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
      kbdInteractiveAuthentication = false;
      passwordAuthentication = false;
    };

    user.openssh.authorizedKeys.keys =
      if config.user.name == "c1"
      then []
      else [];
  };
}
