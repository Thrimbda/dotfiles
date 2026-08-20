{ lib, pkgs, ... }:

with lib;
let
  rustdeskPackage = (import ./_rustdesk-package.nix { inherit pkgs; }).package;
in
{
  modules.desktop.audio.hdmi = {
    enable = true;
    card = "alsa_card.pci-0000_01_00.1";
    sink = "alsa_output.pci-0000_01_00.1.hdmi-stereo";
    lowPrioritySinks = [ "alsa_output.pci-0000_11_00.6.iec958-stereo" ];
  };

  modules.services.todesk.enable = true;
  modules.services.docker.package = pkgs.docker_29;
  modules.virt.libvirt.enable = true;
  modules.profiles.workstation = {
    logrotate.disableConfigCheck = true;
    userManager.oomScoreAdjust = 0;
    networkManager.ethernetInterfaces = [ "enp14s0" ];
    zram.enable = true;
  };
  modules.system.firewall.lanTcpAllows = [{
    source = "192.168.50.0/24";
    ports = [ 5173 8765 ];
    comment = "Allow the local research workbench only from the home LAN.";
  }];

  user.linger = true;
  user.packages = [
    pkgs.unstable.antigravity-ide-fhs
    pkgs.aria2
    pkgs.feishu
    pkgs.git-lfs
    pkgs.htop
    pkgs.k9s
    pkgs.kubectl
    pkgs.nvtopPackages.nvidia
    rustdeskPackage
    pkgs.sops
    pkgs.uv
  ];

  modules.desktop.apps.discord.package = pkgs.unstable.vesktop.override (
    optionalAttrs (pkgs.unstable.vesktop.override.__functionArgs ? pnpm_10_29_2) {
      pnpm_10_29_2 = pkgs.unstable.pnpm_10;
    }
  );

  modules.desktop.apps.clash-verge = {
    servicePolicy = {
      enable = true;
      memoryMin = "256M";
      memoryLow = "1G";
      oomPolicy = "stop";
      oomScoreAdjust = -850;
    };
    guiAutostart = {
      enable = true;
      memoryLow = "256M";
      oomScoreAdjust = 0;
    };
  };

  modules.services.healthchecks.checks.clash-verge-healthcheck = {
    description = "Clash Verge service-mode health check";
    runtimeDirectory = "axiom-healthchecks";
    stateFile = "clash-verge.failures";
    threshold = 2;
    failureMessage = "clash-verge service/core health check failed";
    restartUnit = "clash-verge.service";
    after = [ "clash-verge.service" ];
    wants = [ "clash-verge.service" ];
    serviceCore = {
      enable = true;
      service = "clash-verge.service";
      childPattern = "verge-mihomo|mihomo|clash";
      interfaces = [ "Mihomo" "Meta" ];
    };
  };

  modules.agenix.sshKey = "/etc/ssh/ssh_host_ed25519_key";
  networking.firewall.allowedTCPPorts = [ 22 ];
}
