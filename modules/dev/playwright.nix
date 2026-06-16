{ hey, lib, config, options, pkgs, hostSystem ? null, ... }:

with lib;
with hey.lib;
let
  devCfg = config.modules.dev;
  cfg = devCfg.playwright;
  system = if hostSystem != null then hostSystem else pkgs.stdenv.hostPlatform.system;
  isDarwin = hasSuffix "-darwin" system;
in {
  options.modules.dev.playwright = {
    enable = mkBoolOpt false;
    xdg.enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable (mkMerge [
    {
      user.packages = [ pkgs.playwright-test ];

      environment.shellAliases = {
        pw = "playwright";
      };
    }

    (mkIf isDarwin {
      home.packages = [ pkgs.playwright-test ];
    })
  ]);
}
