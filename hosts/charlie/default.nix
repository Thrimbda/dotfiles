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
      # emacs.enable = true;
    };

    # services = {
    #   cloudflared.enable = true;
    # };
  };

  ## Local configuration
  config = { config, pkgs, ... }:
    let
      userHome = config.user.home;
      opencodeDir = "${userHome}/.opencode";
      opencodeLogDir = "${userHome}/Library/Logs";
    in {
      users.users.c1 = {
        name = "c1";
        home = userHome;
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
      OPENCODE_ENABLE_EXA = "1";
      OPENCODE_EXPERIMENTAL = "true";
    };

    launchd.user.agents.autossh-reverse-ssh = {
      serviceConfig = {
        ProgramArguments = [
          "${pkgs.autossh}/bin/autossh"
          "-M"
          "0"
          "-N"
          "-o"
          "ServerAliveInterval=30"
          "-o"
          "ServerAliveCountMax=3"
          "-o"
          "ExitOnForwardFailure=yes"
          "-R"
          "127.0.0.1:2222:127.0.0.1:22"
          "root@8.159.128.125"
        ];
        EnvironmentVariables = {
          AUTOSSH_GATETIME = "0";
        };
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/tmp/autossh-reverse-ssh.out.log";
        StandardErrorPath = "/tmp/autossh-reverse-ssh.err.log";
      };
    };

    launchd.user.agents.opencode-server = {
      serviceConfig = {
        ProgramArguments = [
          "${opencodeDir}/bin/opencode"
          "serve"
          "--hostname"
          "127.0.0.1"
          "--port"
          "4096"
        ];
        EnvironmentVariables = {
          HOME = userHome;
          OPENCODE_ENABLE_EXA = "1";
          OPENCODE_EXPERIMENTAL = "true";
        };
        WorkingDirectory = userHome;
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "${opencodeLogDir}/opencode-server.out.log";
        StandardErrorPath = "${opencodeLogDir}/opencode-server.err.log";
      };
    };

    user.packages = with pkgs; [
      htop
      coreutils
      curl
      git
      vim
      k9s
      kubectl
      cloudflared
      autossh
      lazygit
    ];

    modules.services.cloudflared = {
      enable = true;
      tunnelId = "9f33127c-3a10-47dc-9383-e27115780db8";
      credentialsFile = ./secrets/cloudflared-credentials.age;
      warpRouting.enabled = false;
      extraConfig = {
        tunnelName = "home-charlie";
        ingress = [
          {
            hostname = "opencode-charlie.0xc1.space";
            service = "http://127.0.0.1:4096";
          }
          { service = "http_status:404"; }
        ];
      };
    };

    modules.agenix.sshKey = "${userHome}/.ssh/id_ed25519";

    system.primaryUser = "c1";
    system.stateVersion = 6;
  };
}
