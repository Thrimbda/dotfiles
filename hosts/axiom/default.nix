# Axiom -- C1's Ryzen 9950X + RTX 5090 workstation

{ ... }:

{
  system = "x86_64-linux";

  imports = [
    ./modules/acorn.nix
    ./modules/rustdesk.nix
    ./modules/qwen.nix
    ./modules/autossh.nix
    ./modules/caelestia.nix
    ./modules/cloudflare.nix
    ./modules/hyprland-hotplug-guard.nix
    ./modules/nvidia-driver.nix
    ./modules/workstation.nix
  ];

  modules = {
    theme = {
      active = "autumnal";
      wallpapers."*" = {
        path = "/home/c1/the-great-sage.jpg";
      };
    };

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
      caelestia.wallpaper.enable = true;
      hyprland = {
        enable = true;
        extraConfig = ''
          hl.config({
            render = {
              -- Work around Hyprland 0.53.x color-management crashes on DPMS/resume.
              -- HDR is lower priority than 240Hz and needs color management, so keep
              -- this guard until the Axiom session is re-tested on the real display.
              cm_enabled = false,
            },
          })

          hl.config({
            misc = {
              -- Permit relaunching the Caelestia WlSessionLock client if it exits.
              allow_session_lock_restore = true,
              -- DPMS wake must be handled by the compositor while the lock surface owns input.
              key_press_enables_dpms = true,
              mouse_move_enables_dpms = true,
            },
          })

          hl.config({
            cursor = {
              -- XDPH cannot embed a hardware cursor in RustDesk's capture.
              no_hardware_cursors = true,
            },
          })
        '';
        monitors = [
          {
            output = "DP-4";
            modePolicy = "native-max-refresh";
            fallbackMode = "3840x2160@240";
            position = "0x0";
            scale = 1.5;
            primary = true;
            match = {
              make = "Microstep";
              model = "MPG272UX OLED";
              serial = "0x01010101";
            };
          }
          {
            output = "DP-5";
            modePolicy = "native-max-refresh";
            fallbackMode = "3840x2160@60";
            position = "2560x0";
            scale = 1.5;
            match = {
              make = "Dell Inc.";
              model = "DELL U2720QM";
              serial = "42N2YG3";
            };
          }
        ];
        monitorHotplug = {
          enable = true;
          unknown = {
            enable = true;
            modePolicy = "native-max-refresh";
            position = "auto";
            scale = 1.5;
          };
        };
        hypridle.enable = false;
        workspaces.secondary.enable = true;
      };
      apps = {
        clash-verge.enable = true;
        discord.enable = true;
        sidra.enable = true;
        steam = {
          enable = true;
          dwproton.enable = true;
        };
        thunar.enable = true;
      };
      input = {
        colemak.enable = true;
        fcitx5 = {
          enable = true;
          rime.enable = true;
          pinyin.enable = true;
        };
      };
      browsers.zen.enable = true;
      term = {
        default = "foot";
        foot.enable = true;
      };
      media.video.enable = true;
    };

    dev = {
      node.enable = true;
      deno.enable = true;
      playwright.enable = true;
      rust.enable = true;
      python.enable = true;
      java.enable = true;
    };
    editors = {
      default = "nvim";
      vim.enable = true;
      vscode.enable = true;
    };
    shell = {
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
      gnome-keyring.enable = true;
    };
    system.utils.enable = true;
  };

  hardware = { ... }: {
    boot.supportedFilesystems = [ "ntfs" ];

    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos-2t";
      fsType = "ext4";
      options = [ "noatime" ];
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-label/AXIOM2T";
      fsType = "vfat";
    };

    swapDevices = [ { device = "/dev/disk/by-label/swap-2t"; } ];
  };
}
