# modules/dev/deno.nix --- https://nodejs.org/en/
#
# Deno is amazingly a future of JavaScript/TypeScript.

{ config, options, lib, pkgs, ... }:

with lib;
with lib.my;
let
  devCfg = config.modules.dev;
  cfg = devCfg.deno;
in
{
  options.modules.dev.deno = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = [
      pkgs.deno
    ];
  };
}
