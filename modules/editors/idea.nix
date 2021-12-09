# Jetbrains 就是站着还把钱挣了。

{ config, options, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.editors.idea;
in {
  options.modules.editors.idea = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      jetbrains.idea-community
    ];

  };
}
