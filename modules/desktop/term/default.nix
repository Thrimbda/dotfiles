{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop.term;
in {
  options.modules.desktop.term = {
    default = mkOpt types.str "xterm";
    font = {
      name = mkOpt types.str "FiraCode Nerd Font Mono";
      size = mkOpt types.float 9.5;
      package = mkOpt types.package pkgs.nerd-fonts.fira-code;
    };
  };

  config = {
    hey.info.term.font = removeAttrs cfg.font [ "package" ];

    services.xserver.desktopManager.xterm.enable = mkDefault (cfg.default == "xterm");

    environment.sessionVariables.TERMINAL = cfg.default;
  };
}
