{ pkgs, modulesPath, config, lib, ... }:
{
  imports = [
    ../home.nix
    ../server.nix
    "${modulesPath}/virtualisation/azure-common.nix"
    # ./hardware-configuration.nix
  ];

  ## Modules
  modules = {
    dev = {
      # cc.enable = true;
      # go.enable = true;
      node.enable = true;
      rust.enable = true;
      python.enable = true;
      scala.enable = true;
    };
    editors = {
      default = "nvim";
      # emacs.enable = true;
      vim.enable = true;
    };
    shell = {
      adl.enable = true;
      # vaultwarden.enable = true;
      direnv.enable = true;
      git.enable    = true;
      gnupg.enable  = true;
      tmux.enable   = true;
      zsh.enable    = true;
    };
    services = {
      ssh.enable = true;
      docker.enable = true;
    };
    theme.active = "alucard";
    theme.useX = false;
  };

  networking.firewall = {
    allowedTCPPorts = [ 34197 ];
    allowedUDPPorts = [ 34197 ];
  };

  ## Local config
  programs.ssh.startAgent = true;
  services.openssh.startWhenNeeded = true;

  # networking.networkmanager.enable = true;
  # The global useDHCP flag is deprecated, therefore explicitly set to false
  # here. Per-interface useDHCP will be mandatory in the future, so this
  # generated config replicates the default behaviour.
  networking.useDHCP = true;

  time.timeZone = "Asia/Shanghai";
  networking.hostName = "acorn";
  networking.dhcpcd.enable = true;
  
  systemd.services."serial-getty@ttyS0".enable = lib.mkForce true;
  systemd.services."serial-getty@hvc0".enable = lib.mkForce true;
  systemd.services."getty@tty1".enable = lib.mkForce true;
  systemd.services."autovt@".enable = lib.mkForce true;

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/ESP";
    fsType = "vfat";
  };
}
