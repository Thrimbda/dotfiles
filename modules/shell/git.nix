{ hey, lib, config, options, pkgs, hostSystem ? null, ... }:

with lib;
with hey.lib;
let
  cfg = config.modules.shell.git;
  system = if hostSystem != null then hostSystem else pkgs.stdenv.hostPlatform.system;
  isDarwin = hasSuffix "-darwin" system;
  gitPackagesBase = with pkgs; [
    git-annex
    gh
    git-open
    diff-so-fancy
    act
  ];
  gitPackages =
    gitPackagesBase
    ++ optional config.modules.shell.gnupg.enable pkgs.git-crypt;
in {
  options.modules.shell.git = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable (mkMerge [
    {
      user.packages = gitPackages;

      home.configFile = {
        "git/config".source = "${hey.configDir}/git/config";
        "git/ignore".source = "${hey.configDir}/git/ignore";
        "git/attributes".source = "${hey.configDir}/git/attributes";
      };

      modules.shell.zsh.rcFiles = [ "${hey.configDir}/git/aliases.zsh" ];
    }
    (mkIf isDarwin {
      home.packages = gitPackages;
    })
  ]);
}
