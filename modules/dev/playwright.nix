{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let
  devCfg = config.modules.dev;
  cfg = devCfg.playwright;
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

    (mkIf pkgs.stdenv.isDarwin {
      home.packages = [ pkgs.playwright-test ];
    })
  ]);
}
