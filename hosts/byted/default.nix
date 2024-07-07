{ pkgs, config, lib, ... }:
{
  imports = [
    ../home.nix
    ./hardware-configuration.nix
    ./networking.nix
  ];

  ## Modules
  modules = {
    dev = {
      # cc.enable = true;
      go.enable = true;
      node.enable = true;
      rust.enable = true;
      rust.enableGlobally = true;
      python.enable = true;
      python.enableGlobally = true;
      scala.enable = true;
    };
    editors = {
      default = "nvim";
      # emacs.enable = true;
      vim.enable = true;
    };
    shell = {
      # adl.enable = true;
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
      vscode-server.enable = true;
      # onedrive.enable = true;
      # Needed occasionally to help the parental units with PC problems
      # teamviewer.enable = true;
    };
#    theme.active = "alucard";
  };


  ## Local config
  programs.ssh.startAgent = true;
  services.openssh.startWhenNeeded = true;

  networking.networkmanager.enable = true;
  # The global useDHCP flag is deprecated, therefore explicitly set to false
  # here. Per-interface useDHCP will be mandatory in the future, so this
  # generated config replicates the default behaviour.
  networking.useDHCP = false;

  #services.xserver = {
  #  layout = "us";
  #  xkbVariant = "colemak";
  #  enable = true;
  #};
  #console.useXkbConfig = true;

  #i18n.inputMethod.enabled =  "fcitx5";
  #i18n.inputMethod.fcitx5.addons = with pkgs; [
  #  fcitx5-rime
  #];

  time.timeZone = "Asia/Shanghai";


  ## Personal backups
  # Syncthing is a bit heavy handed for my needs, so rsync to my NAS instead.
  # systemd = {
  #   services.backups = {
  #     description = "Backup /usr/store to NAS";
  #     wants = [ "usr-drive.mount" ];
  #     path  = [ pkgs.rsync ];
  #     environment = {
  #       SRC_DIR  = "/usr/store";
  #       DEST_DIR = "/usr/drive";
  #     };
  #     script = ''
  #       rcp() {
  #         if [[ -d "$1" && -d "$2" ]]; then
  #           echo "---- BACKUPING UP $1 TO $2 ----"
  #           rsync -rlptPJ --chmod=go= --delete --delete-after \
  #               --exclude=lost+found/ \
  #               --exclude=@eaDir/ \
  #               --include=.git/ \
  #               --filter=':- .gitignore' \
  #               --filter=':- $XDG_CONFIG_HOME/git/ignore' \
  #               "$1" "$2"
  #         fi
  #       }
  #       rcp "$HOME/projects/" "$DEST_DIR/projects"
  #       rcp "$SRC_DIR/" "$DEST_DIR"
  #     '';
  #     serviceConfig = {
  #       Type = "oneshot";
  #       Nice = 19;
  #       IOSchedulingClass = "idle";
  #       User = config.user.name;
  #       Group = config.user.group;
  #     };
  #   };
  #   timers.backups = {
  #     wantedBy = [ "timers.target" ];
  #     partOf = [ "backups.service" ];
  #     timerConfig.OnCalendar = "*-*-* 00,12:00:00";
  #     timerConfig.Persistent = true;
  #   };
  # };
}
