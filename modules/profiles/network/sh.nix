# modules/profiles/network/sh.nix --- TODO

{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
mkIf (elem "sh" config.modules.profiles.networks) {
  time.timeZone = "Asia/Shanghai";

  location = {
    latitude = 31.224361;
    longitude = 121.469170;
  };
}
