{ pkgs, config, lib, ... }:
{
  imports = [
    ../home.nix
  ];

  ## Modules
  modules = {
    desktop = {
      term = {
        default = "xst";
        st.enable = true;
      };
    };
    dev = {
      cc.enable = true;
      go.enable = true;
      node.enable = true;
      rust.enable = true;
      rust.enableGlobally = true;
      python.enable = true;
      python.enableGlobally = true;
      scala.enable = true;
      java.enable = true;
    };
    editors = {
      default = "nvim";
      # emacs.enable = true;
      # idea.enable = true;
      vim.enable = true;
      # vscode.enable = true;
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
      k8s.enable = true;
      ssh.enable = true;
    };
    theme.active = "alucard";
  };


  ## Local config
  # programs.ssh.startAgent = true;
  # services.openssh.startWhenNeeded = true;

  # networking.networkmanager.enable = true;
  # The global useDHCP flag is deprecated, therefore explicitly set to false
  # here. Per-interface useDHCP will be mandatory in the future, so this
  # generated config replicates the default behaviour.
  # networking.useDHCP = false;

  time.timeZone = "Asia/Shanghai";
}