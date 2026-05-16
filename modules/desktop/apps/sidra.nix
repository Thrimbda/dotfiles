{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
let
  cfg = config.modules.desktop.apps.sidra;
  defaultPackage = hey.inputs.sidra.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  options.modules.desktop.apps.sidra = with types; {
    enable = mkBoolOpt false;
    package = mkOpt (nullOr package) null;
  };

  config = mkIf cfg.enable {
    user.packages = [
      (if cfg.package != null then cfg.package else defaultPackage)
    ];
  };
}
