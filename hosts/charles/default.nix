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
      playwright.enable = true;
    };

    editors = {
      default = "nvim";
      vim.enable = true;
      # load-path bugs https://github.com/doomemacs/doomemacs/issues/8541#issuecomment-3698465569
      # emacs.enable = true;
    };
  };

  ## Local configuration
  config = { pkgs, ... }: {
    users.users.c1 = {
      name = "c1";
      home = "/Users/c1";
      shell = pkgs.zsh;
    };

    networking.hostName = "charles";

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
      OPENCODE_ENABLE_EXA = "1";
      OPENCODE_EXPERIMENTAL = "true";
    };

    user.packages = with pkgs; [
      pandoc
      coreutils
      curl
      git
      vim
      k9s
      kubectl
      cloudflared
      lazygit
    ];

    system.primaryUser = "c1";
    system.stateVersion = 6;
  };
}
