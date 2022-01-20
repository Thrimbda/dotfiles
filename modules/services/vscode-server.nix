{ config, options, pkgs, lib, ... }:

with lib;
with lib.my;
let cfg = config.modules.services.vscode-server;
in {
  imports = [
    (fetchTarball "https://github.com/msteen/nixos-vscode-server/tarball/master")
  ];

  options.modules.services.vscode-server = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.vscode-server.enable = true;
  };
}
