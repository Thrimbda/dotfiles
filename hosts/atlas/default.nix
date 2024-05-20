{ pkgs, config, lib, ... }:
{
  imports = [
    ../server.nix
    ../home.nix
    ./hardware-configuration.nix
  ];

  ## Modules
  modules = {
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
        default = "xst";
        st.enable = true;
      };
    };
    dev = {
      node.enable = true;
      deno.enable = true;
      rust.enable = true;
      python.enable = true;
      scala.enable = true;
      java.enable = true;
    };
    editors = {
      default = "nvim";
      vim.enable = true;
    };
    shell = {
      adl.enable = true;
      # vaultwarden.enable = true;
      direnv.enable = true;
      git.enable = true;
      gnupg.enable = true;
      tmux.enable = true;
      zsh.enable = true;
    };
    services = {
      k8s.enable = true;
      ssh.enable = true;
      docker.enable = true;
      calibre.enable = true;
    };
    theme.active = "alucard";
    # theme.useX = false;
  };
  ## Local config
  programs.ssh.startAgent = true;
  services.openssh.startWhenNeeded = true;


  # ## rdp
  # services.xserver.desktopManager.plasma5.enable = true;
  # services =
  #   {
  #     xrdp = {
  #       enable = true;
  #       defaultWindowManager = "startplasma-x11";
  #       openFirewall = true;
  #       # xrdp.port = 3389;
  #       # xrdp.address = "
  #     };
  #   };

  # networking.firewall.allowedTCPPorts = [ 3389 ];


  networking.networkmanager.enable = true;
  # The global useDHCP flag is deprecated, therefore explicitly set to false
  # here. Per-interface useDHCP will be mandatory in the future, so this
  # generated config replicates the default behaviour.
  networking.useDHCP = false;

  time.timeZone = "Asia/Shanghai";
}
