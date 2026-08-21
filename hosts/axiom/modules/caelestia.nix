{ config, pkgs, ... }:

let
  opencodeDir = config.modules.services.opencode-server.dir;
  feishuLauncherId = "bytedance-feishu";
  legacyFeishuDesktopId = "bytedance-feishu.desktop";
  idleSettings = {
    lockBeforeSleep = true;
    inhibitWhenAudio = true;
    lockDpmsTimeout = 60;
    timeouts = [
      {
        timeout = 900;
        idleAction = "lock";
      }
      {
        timeout = 1800;
        idleAction = "dpms off";
        returnAction = "dpms on";
      }
    ];
  };
in {
  modules.desktop.input.fcitx5.theme = {
    enable = true;
    name = "FluentDark";
    package = pkgs.fcitx5-fluent;
  };

  modules.desktop.caelestia = {
    settings = {
      general.idle = idleSettings;
      launcher.favouriteApps = [ feishuLauncherId ];
    };
    mutableConfig = {
      enable = true;
      settings.general.idle = idleSettings;
      launcher = {
        favouriteApps = [ feishuLauncherId ];
        removeFavouriteApps = [ legacyFeishuDesktopId ];
      };
    };
    localControls.polkit.enable = true;
    session = {
      extraPath = [ opencodeDir ];
      includePackageDataDirs = true;
    };
  };
}
