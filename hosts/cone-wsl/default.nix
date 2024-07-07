{ pkgs, config, lib, ... }:

with lib;
let
  nixos-wsl = import ./nixos-wsl;
in
{
  imports = [
    ../home.nix
    #./hardware-configuration.nix
    nixos-wsl.nixosModules.wsl
  ];

  boot = {
    loader = {
      efi.canTouchEfiVariables = mkDefault true;
      systemd-boot.configurationLimit = 10;
      systemd-boot.enable = false;
    };
  };

  wsl = {
    enable = true;
    automountPath = "/mnt";
    defaultUser = "c1";
    startMenuLaunchers = true;

    # Enable integration with Docker Desktop (needs to be installed)
    # docker.enable = true;
  };
  ## Modules
  modules = {
    desktop = {
      input = {
        colemak.enable = true;
        fcitx5-rime.enable = true;
      };
    };
    dev = {
      # cc.enable = true;
      go.enable = true;
      node.enable = true;
      deno.enable = true;
      rust.enable = true;
      python.enable = true;
      scala.enable = true;
    };
    editors = {
      default = "nvim";
      emacs.enable = true;
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
      docker.wsl.enable = true;
      # k8s.enable = true;
      # vscode-server.enable = true;
      # Needed occasionally to help the parental units with PC problems
      # teamviewer.enable = true;
    };
    theme.active = "alucard";
    # theme.useX = false;
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
