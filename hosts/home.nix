{ config, lib, ... }:

with builtins;
with lib;
let blocklist = fetchurl https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts;
in {
  networking.extraHosts = ''
    192.168.50.1   router.home

    # Hosts
    ${optionalString (config.time.timeZone == "Asia/Shanghai") ''
        192.168.50.227  atlas.home
      ''}

    # Block garbage
    ${optionalString config.services.xserver.enable (readFile blocklist)}
  '';

  ## Location config -- since Toronto is my 127.0.0.1
  time.timeZone = mkDefault "Asia/Shanghai";
  i18n.defaultLocale = mkDefault "en_US.UTF-8";
  # For redshift, mainly
  location = {
    latitude = 31.177;
    longitude = 121.363;
  };

  # So the vaultwarden CLI knows where to find my server.
  modules.shell.vaultwarden.config.server = "vault.lissner.net";
}
