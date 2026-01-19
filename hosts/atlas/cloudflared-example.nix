# Cloudflare Zero Trust configuration for atlas (Linux server, IP: 192.168.50.227)
#
# This file shows how to configure cloudflared on atlas to enable WARP private routing
# for your home network (192.168.50.0/24).
#
# Prerequisites:
# 1. Run setup script first:
#    $ cd /Users/c1/Work/dotfiles
#    $ ./bin/cloudflared-setup --host atlas --cidr 192.168.50.0/24
#
# 2. This will create encrypted credentials in hosts/atlas/secrets/cloudflared-credentials.age
#
# 3. Add the modules.services.cloudflared configuration below to hosts/atlas/default.nix
#
# 4. Deploy: sudo nixos-rebuild switch --flake .#atlas
#
# After deployment, external devices with WARP client can access:
#   ssh c1@192.168.50.143  # charlie (macOS)
#   ssh c1@192.168.50.227  # atlas (self)

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
        "audio"
        "audio/realtime"
        "ssd"
      ];
    };

    # Cloudflare Zero Trust Tunnel configuration
    services.cloudflared = {
      enable = true;
      # Tunnel ID from 'cloudflared tunnel create home'
      tunnelId = "your-tunnel-id-here";  # REPLACE WITH ACTUAL TUNNEL ID
      
      # Encrypted credentials (created by cloudflared-setup script)
      credentialsFile = ./secrets/cloudflared-credentials.age;
      
      # WARP routing for home network
      warpRouting = {
        enabled = true;
        cidrs = [ "192.168.50.0/24" ];
      };
      
      # Optional additional configuration
      config = {
        # Additional YAML config attributes
        # ingress = [ ... ];
      };
    };

    # Existing desktop configuration
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
        default = "librewolf";
        librewolf.enable = true;
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
      python.enable = true;
      java.enable = true;
    };
    
    editors = {
      default = "nvim";
      vim.enable = true;
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
      kubectl
    ];
    
    programs.ssh.startAgent = true;
    services.openssh.startWhenNeeded = true;
    
    # ISSUE: https://discourse.nixos.org/t/logrotate-config-fails-due-to-missing-group-30000/28501
    services.logrotate.checkConfig = false;

    # Firewall configuration
    # Allow SSH from home network and cloudflared tunnel traffic
    networking.firewall = {
      # High ephemeral ports for various applications
      allowedTCPPortRanges = [{
        from = 49152;
        to = 65535;
      }];
      allowedUDPPortRanges = [{
        from = 49152;
        to = 65535;
      }];
      
      # Explicitly allow SSH from home network
      allowedTCPPorts = [ 22 ];
      
      # Cloudflared may need these ports (check documentation)
      # allowedUDPPorts = [ 7844 ];
    };
    
    # SSH configuration for secure access
    services.openssh = {
      enable = true;
      settings = {
        # Security: require SSH keys, disable passwords
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        KbdInteractiveAuthentication = false;
        
        # For browser SSH emergency access, user 'siyuan.arc' may need password auth
        # PasswordAuthentication = true;  # Enable only for testing browser SSH
      };
      
      # Allow specific users
      allowUsers = [ "c1" "siyuan.arc" ];  # c1 for normal SSH, siyuan.arc for browser SSH
      
      # Host keys
      hostKeys = [
        {
          path = "/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];
    };
  };

  ## Hardware configuration
  hardware = { ... }: {
    networking.interfaces.eno1.useDHCP = true;

    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-label/BOOT";
      fsType = "vfat";
    };

    swapDevices = [ ];
  };
}