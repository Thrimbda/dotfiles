# modules/dev/deno.nix --- https://deno.com/
#
# Deno is amazingly a future of JavaScript/TypeScript.

{ hey, config, options, lib, pkgs, hostSystem ? null, ... }:

with lib;
with hey.lib;
let
  devCfg = config.modules.dev;
  cfg = devCfg.deno;
  system = if hostSystem != null then hostSystem else pkgs.stdenv.hostPlatform.system;
  isDarwin = hasSuffix "-darwin" system;
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
