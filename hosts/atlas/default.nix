{ pkgs, config, lib, ... }:
{
  imports = [
    ../server.nix
    ../home.nix
    ./hardware-configuration.nix
  ];

  ## Modules
  modules = {
    dev = {
      node.enable = true;
      rust.enable = true;
      python.enable = true;
      scala.enable = true;
      java.enable = true;
    };
    editors = {
      default = "nvim";
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
      k8s.enable = true;
      ssh.enable = true;
      docker.enable = true;
      calibre.enable = true;
    };
    theme.active = "alucard";
    theme.useX = false;
  };

  ## Local config
  programs.ssh.startAgent = true;
  services.openssh.startWhenNeeded = true;

  networking.networkmanager.enable = true;
  # The global useDHCP flag is deprecated, therefore explicitly set to false
  # here. Per-interface useDHCP will be mandatory in the future, so this
  # generated config replicates the default behaviour.
  networking.useDHCP = false;

  time.timeZone = "Asia/Shanghai";
}
