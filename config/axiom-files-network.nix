{ config, lib, pkgs, ... }:
let
  tool = pkgs.writeShellScriptBin "axiom-files-network" ''
    exec ${pkgs.python3}/bin/python3 ${../bin/axiom-files-network.py} \
      --home ${lib.escapeShellArg config.user.home}
  '';
in {
  system.build.axiomFilesNetworkTool = tool;
  home-manager.users.${config.user.name} = { lib, ... }: {
    home.activation.axiomFilesNetwork = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${tool}/bin/axiom-files-network
    '';
  };
}
