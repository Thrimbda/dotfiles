# modules/dev/deno.nix --- https://deno.com/
#
# Deno is amazingly a future of JavaScript/TypeScript.

{ hey, config, options, lib, pkgs, isDarwin, ... }:

with lib;
with hey.lib;
let
  devCfg = config.modules.dev;
  cfg = devCfg.deno;
in
{
  options.modules.dev.deno = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable (mkMerge [
    {
      user.packages = [
        pkgs.deno
      ];
    }
    (mkIf isDarwin {
      home.packages = [
        pkgs.deno
      ];
    })
  ]);
}
