{ lib, pkgs, config }:
let
  package = pkgs.stdenvNoCC.mkDerivation {
    pname = "frp-sunshine-relay";
    version = "0.71.0";
    src = pkgs.fetchurl {
      url = "https://github.com/fatedier/frp/releases/download/v0.71.0/frp_0.71.0_linux_amd64.tar.gz";
      hash = "sha256-hPJ+OfERafetzvjotwyTKd4XdHsfFNrZ+5Xu9WgupxY=";
    };
    installPhase = ''
      install -Dm755 frpc "$out/bin/frpc"
      install -Dm755 frps "$out/bin/frps"
    '';
    meta.platforms = [ "x86_64-linux" ];
  };
  tcpPorts = [ 47984 47989 48010 ];
  udpPorts = [ 47998 47999 48000 ];
  auth = {
    method = "token";
    tokenSource = {
      type = "file";
      file.path = config.age.secrets.frp-token.path;
    };
  };
  mkService = executable: settings:
    let configFile = (pkgs.formats.toml {}).generate "${executable}-sunshine.toml" settings;
    in {
      description = "Sunshine dedicated FRP QUIC relay (${executable})";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        User = config.user.name;
        ExecStartPre = "${package}/bin/${executable} verify -c ${configFile}";
        ExecStart = "${package}/bin/${executable} -c ${configFile}";
        Restart = "on-failure";
        RestartSec = "5s";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
      };
    };
in {
  inherit package tcpPorts udpPorts auth mkService;
  port = 7001;
}
