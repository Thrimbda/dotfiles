{ modulesPath, ... }:

{
  system = "x86_64-linux";

  imports = [
    "${modulesPath}/profiles/qemu-guest.nix"
    ./modules/platform.nix
    ./image.nix
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

    dev.node.enable = true;

    services = {
      ssh.enable = true;
      fail2ban.enable = true;
    };

    # Hypridle defaults on in the shared desktop module; this server has no desktop.
    desktop.hyprland.hypridle.enable = false;

    theme.active = null;
  };
}
