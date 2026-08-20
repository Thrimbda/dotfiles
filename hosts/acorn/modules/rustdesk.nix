{ config, lib, pkgs, ... }:

let
  rustdeskSecret = config.age.secrets.rustdesk-server-key;
  rustdeskSecretMetadata =
    "${rustdeskSecret.owner}:${rustdeskSecret.group}:${lib.removePrefix "0" rustdeskSecret.mode}";
  rustdeskKeyPreflight = pkgs.writeShellScript "acorn-rustdesk-key-preflight" ''
    set -eu

    configured=${lib.escapeShellArg rustdeskSecret.path}
    target=$(${pkgs.coreutils}/bin/readlink -e -- "$configured" 2>/dev/null) \
      || exit 1
    [ -n "$target" ] && [ -f "$target" ] && [ ! -L "$target" ] \
      || exit 1
    metadata=$(${pkgs.coreutils}/bin/stat --format='%U:%G:%a' -- "$target" 2>/dev/null) \
      || exit 1
    [ "$metadata" = ${lib.escapeShellArg rustdeskSecretMetadata} ] \
      || exit 1
    [ -r "$target" ] && [ -s "$target" ]
  '';
in {
  age.secrets.rustdesk-server-key = {
    path = "/var/lib/rustdesk/id_ed25519";
    owner = "rustdesk";
    group = "rustdesk";
    mode = "0400";
  };

  assertions = [{
    assertion = lib.versionAtLeast config.services.rustdesk-server.package.version "1.1.14";
    message = "acorn RustDesk Server must stay >= 1.1.14 (client pairing baseline)";
  }];

  services.rustdesk-server = {
    enable = true;
    openFirewall = false;
    package = pkgs.rustdesk-server.overrideAttrs (oldAttrs: {
      patches = (oldAttrs.patches or []) ++ [
        ../patches/rustdesk-server-force-relay-intranet.patch
      ];
    });
    signal = {
      relayHosts = [ "rustdesk.0xc1.wang" ];
      extraArgs = [ "-k" "_" ];
    };
    relay.extraArgs = [ "-k" "_" ];
  };

  systemd.tmpfiles.rules = [
    "L+ /var/lib/rustdesk/id_ed25519.pub - - - - ${../secrets/rustdesk-server-key.pub}"
  ];

  systemd.services.rustdesk-signal = {
    environment.ALWAYS_USE_RELAY = "Y";
    restartTriggers = [
      ../secrets/rustdesk-server-key.age
      ../secrets/rustdesk-server-key.pub
    ];
    serviceConfig = {
      ExecStartPre = [
        rustdeskKeyPreflight
        "${pkgs.coreutils}/bin/test -r /var/lib/rustdesk/id_ed25519.pub"
        "${pkgs.coreutils}/bin/test -s /var/lib/rustdesk/id_ed25519.pub"
      ];
      LimitCORE = 0;
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  systemd.services.rustdesk-relay = {
    restartTriggers = [
      ../secrets/rustdesk-server-key.age
      ../secrets/rustdesk-server-key.pub
    ];
    serviceConfig = {
      ExecStartPre = [
        rustdeskKeyPreflight
        "${pkgs.coreutils}/bin/test -r /var/lib/rustdesk/id_ed25519.pub"
        "${pkgs.coreutils}/bin/test -s /var/lib/rustdesk/id_ed25519.pub"
      ];
      LimitCORE = 0;
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
