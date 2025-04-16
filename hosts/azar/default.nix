
{ hey, lib, ... }:

with lib;
with builtins;
{
  system = "x86_64-linux";

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

      # Wayland only
      hyprland = rec {
        enable = true;
        monitors = [
          { output = "DP-3";
            scale = 2;
            position = "0x0";
            primary = true; }
          { output = "DP-2";
            scale = 2;
            position = "1920x0"; }
        ];
        extraConfig = ''
          # REVIEW: Might be a hyprland bug, but an "Unknown-1" display is
          #   always created and reserves some desktop space, so I disable it.
          monitor = Unknown-1,disable

          # Bind fixed workspaces to external monitors
          workspace = name:left, monitor:DP-3, default:true
           workspace = name:right, monitor:DP-2, default:true

          # exec-once = hyprctl keyword monitor HDMI-A-1,disable
        '';
      };

      term.default = "foot";
      term.foot.enable = true;

      apps.thunar.enable = true;
      apps = {
        rofi.enable = true;
        steam = {
          enable = true;
          # libraryDir = "/media/windows/Program Files (x86)/Steam";
        };
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

      media.video.enable = true;
      # media.video.capture.enable = true;
    };
    dev = {
      node.enable = true;
      deno.enable = true;
      rust.enable = true;
    };
    editors = {
      default = "nvim";
      # emacs.enable = true;
      vim.enable = true;
      vscode.enable = true;
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
      gnome-keyring.enable = true;
    };
    system = {
      utils.enable = true;
      fs.enable = true;
    };
  };

  hardware = { ... }: {

    networking.networkmanager.enable = true;
    networking.interfaces.eno1.useDHCP = true;

    boot.supportedFilesystems = [ "ntfs" ];
  # Displays
  # services.xserver = {
    # This must be done manually to ensure my screen spaces are arranged exactly
    # as I need them to be *and* the correct monitor is "primary". Using
    # xrandrHeads does not work.
#    monitorSection = ''
#      VendorName  "Unknown"
#      ModelName   "DELL U2720QM"
#      HorizSync   30.0 - 135.0
#      VertRefresh 56.0 - 86.0
#      Option      "DPMS"
#    '';
#    screenSection = ''
#      Option "metamodes" "HDMI-0: nvidia-auto-select +1920+0, DVI-I-1: nvidia-auto-select +0+180, DVI-D-0: nvidia-auto-select +4480+180"
#      Option "SLI" "Off"
#      Option "MultiGPU" "Off"
#      Option "BaseMosaic" "off"
#      Option "Stereo" "0"
#      Option "nvidiaXineramaInfoOrder" "DFP-1"
#    '';
  # };
    fileSystems = {
      "/" = {
        device = "/dev/disk/by-label/nixos";
        fsType = "ext4";
        options = [ "noatime" ];
      };
      "/boot" = {
        device = "/dev/disk/by-label/BOOT";
        fsType = "vfat";
      };
      # "/media/windows" = {
      #   device = "/dev/disk/by-label/windows";
      #   fsType = "ntfs";
      #   options = [ "defaults" "noauto" "nofail" "noatime" "nodev" "exec" "umask=000" "uid=1000" "gid=1000" "x-systemd.automount" ];
      # };
    };
    swapDevices = [ ];
  };

  ## Local config
  config = { pkgs, ... }: {

    user.packages = with pkgs; [
      k9s
      kubectl
    ];
    programs.ssh.startAgent = true;
    services.openssh.startWhenNeeded = true;
    # ISSUE: https://discourse.nixos.org/t/logrotate-config-fails-due-to-missing-group-30000/28501
    services.logrotate.checkConfig = false;

  };
}
