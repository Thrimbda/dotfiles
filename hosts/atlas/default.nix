{ hey, lib, ... }:

with lib;
with builtins;
{

  system = "x86_64-linux";

  ## Modules
  modules = {
    theme.active = "autumnal";
    xdg.ssh.enable = true;
    # theme.useX = false;

    profiles = {
      role = "workstation";
      user = "c1";
      networks = [ "sh" ];
      hardware = [
        "cpu/amd"
        # "gpu/amd"
        "audio"
        "audio/realtime"
        "ssd"
      ];
    };
    # Sometimes it dies, and I need to see why.
    desktop = {
      bspwm.enable = true;
      apps = {
        rofi.enable = true;
      };
      input = {
        colemak.enable = true;
        fcitx5-rime.enable = true;
      };
      browsers = {
        default = "firefox";
        firefox.enable = true;
        chrome.enable = true;
      };
      term = {
        default = "foot";
        st.enable = true;
      };
    };
    dev = {
      node.enable = true;
      deno.enable = true;
      rust.enable = true;
      # python.enable = true;
      # scala.enable = true;
      java.enable = true;
    };
    editors = {
      default = "nvim";
      vim.enable = true;
    };
    shell = {
      # vaultwarden.enable = true;
      direnv.enable = true;
      git.enable = true;
      gnupg.enable = true;
      tmux.enable = true;
      zsh.enable = true;
    };
    services = {
      ssh.enable = true;
      docker.enable = true;
      calibre.enable = true;
    };
    system = {
      utils.enable = true;
      fs.enable = true;
    };
  };
  ## Local config
  config = {pkgs, ...}: {

    user.packages = with pkgs; [
      k9s
    ];
    programs.ssh.startAgent = true;
    services.openssh.startWhenNeeded = true;
    # ISSUE: https://discourse.nixos.org/t/logrotate-config-fails-due-to-missing-group-30000/28501
    services.logrotate.checkConfig = false;
  };

  ## hardware
  hardware = { ... }: {
    networking.interfaces.eno1.useDHCP = true;

    fileSystems."/" =
      { device = "/dev/disk/by-label/nixos";
        fsType = "ext4";
      };

    fileSystems."/boot" =
      { device = "/dev/disk/by-label/BOOT";
        fsType = "vfat";
      };

    swapDevices = [ ];
  };

}
