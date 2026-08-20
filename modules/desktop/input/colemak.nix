{ hey, options, config, lib, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop.input.colemak;
in {
  options.modules.desktop.input.colemak = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.xserver.xkb = {
        layout = "us";
        variant = "colemak";
      };
      console.useXkbConfig = true;
      # This used to inherit true from the unconditional Xorg service.
      programs.ssh.enableAskPassword = mkDefault true;
    }

    (mkIf (config.modules.desktop.type == "x11") {
      services.xserver.enable = true;
    })
  ]);
}
