{ hey, lib, config, pkgs, hostSystem ? null, ... }:

with lib;
with hey.lib;
let
  cfg = config.modules.system.firewall;
  system = if hostSystem != null then hostSystem else pkgs.stdenv.hostPlatform.system;
  isLinux = hasSuffix "-linux" system;
  mkLanTcpAllow = rule: ''
    # ${rule.comment}
    iptables -w -A nixos-fw -s ${escapeShellArg rule.source} -p tcp -m multiport --dports ${escapeShellArg (concatMapStringsSep "," toString rule.ports)} -j nixos-fw-accept
  '';
in {
  options.modules.system.firewall = with types; {
    lanTcpAllows = mkOpt (listOf (submodule {
      options = {
        source = mkOpt str "";
        ports = mkOpt (listOf int) [];
        comment = mkOpt str "LAN TCP allow";
      };
    })) [];
  };

  config = mkIf (isLinux && cfg.lanTcpAllows != []) {
    networking.firewall.extraCommands = concatMapStringsSep "\n" mkLanTcpAllow cfg.lanTcpAllows;
  };
}
