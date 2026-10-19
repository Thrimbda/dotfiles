{ config, pkgs, ... }:
{
  home-manager.users.${config.user.name} = { lib, ... }: {
    home.activation.seedWritableSsh = lib.hm.dag.entryBetween
      [ "linkGeneration" ] [ "writeBoundary" ] ''
        run ${pkgs.coreutils}/bin/env PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.gnugrep pkgs.openssh ]} \
          ${pkgs.runtimeShell} ${../../bin/ssh-config-apply} \
          ${lib.escapeShellArg config.user.home} ${./.} ${../../bin/ssh-route-probe}
      '';
  };
}
