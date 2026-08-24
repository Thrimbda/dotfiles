{ modulesPath, ... }:

{
  system = "x86_64-linux";

  imports = [
    "${modulesPath}/profiles/qemu-guest.nix"
    ./modules/auth-mini.nix
    ./modules/cybion.nix
    ./modules/ingress.nix
    ./modules/oneex-portfolio-adapter.nix
    ./modules/platform.nix
    ./modules/rustdesk.nix
    ./modules/vaultwarden.nix
  ];

  modules = {
    profiles = {
      user = "c1";
      role = "server";
    };

    editors = {
      default = "nvim";
      vim.enable = true;
    };

    shell = {
      git.enable = true;
      tmux.enable = true;
      zsh.enable = true;
    };

    services = {
      ssh.enable = true;
      fail2ban.enable = true;
      frp.server.enable = true;
      nginx.enable = true;
    };

    # Hypridle defaults on in the shared desktop module; this server has no desktop.
    desktop.hyprland.hypridle.enable = false;

    theme.active = null;
  };
}
