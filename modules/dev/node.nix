# modules/dev/node.nix --- https://nodejs.org/en/
#
# JS is one of those "when it's good, it's alright, when it's bad, it's a
# disaster" languages.

{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let
  devCfg = config.modules.dev;
  cfg = devCfg.node;
  nodePkg = pkgs.nodejs_latest;
  nodePackages = [
    nodePkg
    # pkgs.yarn
  ];
  npmDataDir =
    if cfg.xdg.enable or false
    then "${config.home.dataDir}/npm"
    else "$HOME/.npm";
  npmCacheDir =
    if cfg.xdg.enable or false
    then "${config.home.cacheDir}/npm"
    else "$HOME/.cache/npm";
  npmTmpDir =
    if cfg.xdg.enable or false
    then "$XDG_RUNTIME_DIR/npm"
    else "$TMPDIR/npm";
  npmConfigFile =
    if cfg.xdg.enable or false
    then "$XDG_CONFIG_HOME/npm/config"
    else "$HOME/.npmrc";
  npmBinDir = "${npmDataDir}/bin";
in {
  options.modules.dev.node = {
    enable = mkBoolOpt false;
    xdg.enable = mkBoolOpt false;
  };

  config = mkMerge [
    (mkIf cfg.enable (mkMerge [
      {
        user.packages = nodePackages;

        # # Run locally installed bin-script, e.g. n coffee file.coffee
        environment.shellAliases = {
          n  = "PATH=\"$(${nodePkg}/bin/npm bin):$PATH\"";
          ya = "yarn";
        };

        # environment.variables.PATH = [ "$(${pkgs.yarn}/bin/yarn global bin)" ];
      }

      (mkIf pkgs.stdenv.isDarwin {
        home.packages = nodePackages;
        modules.shell.zsh.envInit = mkBefore ''
          path=( "${npmBinDir}" "''${path[@]}" )
          typeset -U path PATH
        '';
      })
    ]))

    (mkIf cfg.xdg.enable {
      # NPM refuses to adopt XDG conventions upstream, so I enforce it myself.
      environment.variables = {
        NPM_CONFIG_USERCONFIG = npmConfigFile;
        NPM_CONFIG_CACHE      = npmCacheDir;
        NPM_CONFIG_PREFIX     = npmDataDir;
        NPM_CONFIG_TMP        = npmTmpDir;
        NODE_REPL_HISTORY     = "${config.home.cacheDir}/node/repl_history";
      };

      home.configFile."npm/config".text = ''
        cache=${config.home.cacheDir}/npm
        prefix=${config.home.dataDir}/npm
        tmp=$XDG_RUNTIME_DIR/npm
      '';

      home.file = {
        ".local/share/npm/.keep".text = "";
        ".cache/npm/.keep".text = "";
      };
    })
  ];
}
