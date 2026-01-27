{ hey, lib, ... }:

with lib;
{
  os = "darwin";
  system = "aarch64-darwin";

  ## Modules
  user = {
    name = "c1";
    home = "/Users/c1";
  };

  modules = {
    theme.active = "autumnal-cli";

    shell = {
      direnv.enable = true;
      zsh.enable = true;
      git.enable = true;
      gnupg.enable = true;
      tmux.enable = true;
    };

    dev = {
      node.enable = true;
      node.xdg.enable = true;
      deno.enable = true;
      rust.enable = true;
      python.enable = true;
    };

    editors = {
      default = "nvim";
      vim.enable = true;
      # emacs.enable = true;
    };

    # services = {
    #   cloudflared.enable = true;
    # };
  };

  ## Local configuration
  config = { pkgs, ... }: {
    users.users.c1 = {
      name = "c1";
      home = "/Users/c1";
      shell = pkgs.zsh;
    };

    networking.hostName = "charlie";

    security.pam.services.sudo_local.touchIdAuth = true;

    system.defaults = {
      NSGlobalDomain = {
        ApplePressAndHoldEnabled = false;
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
      };
      dock = {
        autohide = false;
        tilesize = 48;
        largesize = 64;
        orientation = "left";
      };
      finder.AppleShowAllFiles = true;
    };

    environment.variables = {
      PATH = "$HOME/.opencode/bin:$PATH";
    };

    user.packages = with pkgs; [
      coreutils
      curl
      git
      vim
      k9s
      kubectl
      cloudflared
    ];

    # modules.services.cloudflared = {
    #   enable = true;
    #   # TODO: Replace with actual tunnel ID after running cloudflared-setup
    #   tunnelId = "9f33127c-3a10-47dc-9383-e27115780db8";
    #   # TODO: Create credentials file with agenix
    #   credentialsFile = ./secrets/cloudflared-credentials.age;
    #   warpRouting = {
    #     enabled = false;
    #     # cidrs = [ "192.168.50.0/24" ];
    #   };
    #   extraConfig = {
    #     tunnelName = "home-charlie";
    #     ingress = [
    #       { hostname = "charlie-ssh.0xc1.space"; service = "ssh://localhost:22"; }
    #       { service = "http_status:404"; }
    #     ];
    #   };
    # };

    modules.agenix.sshKey = "/Users/c1/.ssh/id_ed25519";

    system.primaryUser = "c1";
    system.stateVersion = 6;
  };
}
