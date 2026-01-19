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
      emacs.enable = true;
    };

    services = {
      cloudflared.enable = true;
    };
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
      dock.autohide = false;
      dock.orientation = "left";
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
    ];

    modules.services.cloudflared = {
      enable = true;
      # TODO: Replace with actual tunnel ID after running cloudflared-setup
      # tunnelId = "charlie-tunnel-id";
      # TODO: Create credentials file with agenix
      # credentialsFile = ./secrets/cloudflared-credentials.age;
      warpRouting = {
        enabled = true;
        cidrs = [ "192.168.50.0/24" ];
      };
      config = {
        tunnelName = "home-charlie";
      };
    };

    system.primaryUser = "c1";
    system.stateVersion = 6;
  };
}
