{ hey, lib, config, options, pkgs, hostSystem ? null, ... }:

with lib;
with hey.lib;
let cfg = config.modules.shell.tmux;
    system = if hostSystem != null then hostSystem else pkgs.stdenv.hostPlatform.system;
    isDarwin = hasSuffix "-darwin" system;
in {
  options.modules.shell.tmux = with types; {
    enable = mkBoolOpt false;
    term = mkOpt str "xterm-256color";
    rcFiles = mkOpt (listOf (either str path)) [];
  };

  config = mkIf cfg.enable (mkMerge [
    {
      environment.variables.TMUX_HOME = "$XDG_CONFIG_HOME/tmux";

      # I avoid programs.tmux because it comes with extra magic I don't need.
      user.packages = [ pkgs.tmux ];

      environment.etc."tmux.conf".text = with pkgs.tmuxPlugins; ''
        set -s default-terminal "${cfg.term}"

        source-file '${config.home.configDir}/tmux/tmux.conf'
        ${concatMapStrings (path: "source-file '${path}'\n") cfg.rcFiles}

        # Run plugins
        run-shell ${yank.rtp}
      '';

      home.configFile."tmux" = {
        source = "${hey.configDir}/tmux";
        recursive = true;
      };

      modules.shell.zsh.rcFiles = [ "${hey.configDir}/tmux/aliases.zsh" ];
    }

    (mkIf isDarwin {
      home.packages = [ pkgs.tmux ];
    })
  ]);
}
