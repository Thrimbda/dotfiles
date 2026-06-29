{ lib, config, ... }:

with lib;
let
  cfg = config.modules.theme or {};
  themeName = cfg.active or null;
in {
  options.modules.theme.active = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = "Active CLI theme.";
  };

  config = mkIf (themeName != null) {
    hey.info.theme = { active = themeName; };
  };
}
