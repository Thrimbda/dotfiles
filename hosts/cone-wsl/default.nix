{ hey, pkgs, config, lib, ... }:

with lib;
with builtins;
let
  nixos-wsl = import ./nixos-wsl;
in
{
  system = "x86_64-linux";

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
    theme.active = "autumnal";
    xdg.ssh.enable = true;

    profiles = {
      role = "workstation";
      user = "c1";
      networks = [ "sh" ];
      hardware = [
        "cpu/amd"
        "gpu/nvidia"
        "audio"
        "audio/realtime"
        "ssd"
        "bluetooth"
        "wifi"
      ];
    };

    desktop = {
      input = {
        colemak.enable = true;
        fcitx5-rime.enable = true;
      };
    };
    dev = {
      # cc.enable = true;
      # go.enable = true;
      node.enable = true;
      deno.enable = true;
      rust.enable = true;
      python.enable = true;
      # scala.enable = true;
    };
    editors = {
      default = "nvim";
      emacs.enable = true;
      vim.enable = true;
    };
    shell = {
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
  };


  hardware = {
    boot.supportedFilesystems = [ "ntfs" ];

    fileSystems."/" =
      { device = "/dev/sdd";
        fsType = "ext4";
      };

    fileSystems."/usr/lib/wsl/drivers" =
      { device = "drivers";
        fsType = "9p";
      };

    fileSystems."/usr/lib/wsl/lib" =
      { device = "lib";
        fsType = "9p";
      };

    fileSystems."/mnt/wsl" =
      { device = "none";
        fsType = "tmpfs";
      };

    fileSystems."/mnt/wslg" =
      { device = "none";
        fsType = "tmpfs";
      };

    fileSystems."/mnt/wslg/doc" =
      { device = "none";
        fsType = "overlay";
      };

    fileSystems."/mnt/c" =
      { device = "drvfs";
        fsType = "9p";
      };

    swapDevices = [ ];
  };

  config = { pkgs, ... }: {
    ## Local config
    programs.ssh.startAgent = true;
    services.openssh.startWhenNeeded = true;
  };
}
