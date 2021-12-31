{ config, options, pkgs, lib, ... }:

with lib;
with lib.my;
let cfg = config.modules.services.k8s;
  kubeMasterIP = "192.168.50.211";
  kubeMasterHostname = "azar";
  kubeMasterAPIServerPort = 6443;
in {
  options.modules.services.k8s = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    # resolve master hostname
    networking.extraHosts = "${kubeMasterIP} ${kubeMasterHostname}";

    # packages for administration tasks
    environment.systemPackages = with pkgs; [
      kompose
      kubectl
      kubernetes
    ];

    services.kubernetes = {
      roles = ["master" "node"];
      masterAddress = kubeMasterHostname;
      apiserverAddress = "https://${kubeMasterHostname}:${toString kubeMasterAPIServerPort}";
      easyCerts = true;
      apiserver = {
        securePort = kubeMasterAPIServerPort;
        advertiseAddress = kubeMasterIP;
      };

      # use coredns
      addons.dns.enable = true;

      # needed if you use swap
      # kubelet.extraOpts = "--fail-swap-on=false";
    };
  };
}
