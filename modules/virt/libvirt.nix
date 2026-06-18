{ hey, lib, config, pkgs, hostSystem ? null, ... }:

with lib;
with hey.lib;
let
  cfg = config.modules.virt.libvirt;
  system = if hostSystem != null then hostSystem else pkgs.stdenv.hostPlatform.system;
  isLinux = hasSuffix "-linux" system;
in {
  options.modules.virt.libvirt = with types; {
    enable = mkBoolOpt false;
    virtManager.enable = mkBoolOpt true;
    swtpm.enable = mkBoolOpt true;
    packages = mkOpt (listOf package) (with pkgs; [
      virt-viewer
      virtio-win
    ]);
    userGroups = mkOpt (listOf str) [ "kvm" "libvirtd" ];
  };

  config = mkIf (cfg.enable && isLinux) {
    user.extraGroups = cfg.userGroups;
    environment.systemPackages = cfg.packages;

    programs.virt-manager.enable = cfg.virtManager.enable;

    virtualisation.libvirtd = {
      enable = true;
      qemu.swtpm.enable = cfg.swtpm.enable;
    };
  };
}
