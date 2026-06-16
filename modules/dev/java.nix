# modules/dev/java.nix --- Poster child for carpal tunnel
#
# TODO

{ hey, lib, config, options, pkgs, hostSystem ? null, ... }:

with lib;
with hey.lib;
let devCfg = config.modules.dev;
    cfg = devCfg.java;
    system = if hostSystem != null then hostSystem else pkgs.stdenv.hostPlatform.system;
    isDarwin = hasSuffix "-darwin" system;
in {
  options.modules.dev.java = {
    enable = mkBoolOpt false;
    xdg.enable = mkBoolOpt false;
  };

  config = mkMerge [
    (mkIf cfg.enable (mkMerge [
      {
        user.packages = [ pkgs.openjdk ];
      }
      (mkIf isDarwin {
        home.packages = [ pkgs.openjdk ];
      })
    ]))

    (mkIf cfg.xdg.enable (
      if isDarwin then {
        environment.variables._JAVA_OPTIONS =
          ''-Djava.util.prefs.userRoot="$XDG_CONFIG_HOME/java"'';
      } else {
        environment.sessionVariables._JAVA_OPTIONS =
          ''-Djava.util.prefs.userRoot="$XDG_CONFIG_HOME/java"'';
      }))
  ];
}
