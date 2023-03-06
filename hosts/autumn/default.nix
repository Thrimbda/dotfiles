{ pkgs, config, lib, ... }:
{
  imports = [
    ../home.nix
    ../server.nix
    ./hardware-configuration.nix
  ];

  ## Modules
  modules = {
    dev = {
      # cc.enable = true;
      go.enable = true;
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
      # onedrive.enable = true;
      # k8s.enable = true;
      # Needed occasionally to help the parental units with PC problems
      # teamviewer.enable = true;
    };
    theme.active = "alucard";
  };

  ## Local config
  programs.ssh.startAgent = true;
  services.openssh.startWhenNeeded = true;

  # networking.networkmanager.enable = true;
  # The global useDHCP flag is deprecated, therefore explicitly set to false
  # here. Per-interface useDHCP will be mandatory in the future, so this
  # generated config replicates the default behaviour.
  # networking.useDHCP = false;

  time.timeZone = "Asia/Shanghai";

}
