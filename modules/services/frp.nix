{ hey, lib, config, pkgs, hostSystem ? null, ... }:

with lib;
with hey.lib;
let
  cfg = config.modules.services.frp;
  system = if hostSystem != null then hostSystem else pkgs.stdenv.hostPlatform.system;
  isLinux = hasSuffix "-linux" system;
  enabled = cfg.server.enable || cfg.client.enable;
  user = if cfg.user != "" then cfg.user else config.user.name;
  tokenSecret = config.age.secrets.${cfg.tokenSecretName};
  tokenPlaceholder = "@FRP_TOKEN@";
  toml = pkgs.formats.toml {};

  serverSettings = recursiveUpdate cfg.server.extraConfig {
    bindAddr = cfg.server.bindAddr;
    bindPort = cfg.server.bindPort;
    auth = (cfg.server.extraConfig.auth or {}) // {
      method = "token";
      token = tokenPlaceholder;
    };
  };

  clientSettings = recursiveUpdate cfg.client.extraConfig ({
    serverAddr = cfg.client.serverAddr;
    serverPort = cfg.client.serverPort;
    auth = (cfg.client.extraConfig.auth or {}) // {
      method = "token";
      token = tokenPlaceholder;
    };
  } // optionalAttrs (cfg.client.proxies != []) {
    proxies = cfg.client.proxies;
  });

  serverTemplate = toml.generate "frps.toml" serverSettings;
  clientTemplate = toml.generate "frpc.toml" clientSettings;

  mkRenderConfig = name: template: pkgs.writeShellScript "render-${name}-config" ''
    set -eu

    token_path=${escapeShellArg tokenSecret.path}
    template=${escapeShellArg template}
    output=/run/${name}/${name}.toml
    tmp=$output.tmp

    IFS= read -r token < "$token_path"
    if [ -z "$token" ]; then
      printf '%s\n' "empty frp token secret: $token_path" >&2
      exit 1
    fi

    umask 077
    while IFS= read -r line || [ -n "$line" ]; do
      printf '%s\n' "''${line//${tokenPlaceholder}/$token}"
    done < "$template" > "$tmp"
    mv "$tmp" "$output"
  '';

  mkService = name: description: template: serviceConfig: {
    inherit description;
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      User = user;
      RuntimeDirectory = name;
      RuntimeDirectoryMode = "0700";
      WorkingDirectory = "/run/${name}";
      ExecStartPre = mkRenderConfig name template;
      ExecStart = "${cfg.package}/bin/${name} -c /run/${name}/${name}.toml";
      Restart = "always";
      RestartSec = cfg.restartSec;
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = "read-only";
      ProtectSystem = "strict";
      ReadWritePaths = [ "/run/${name}" ];
    } // serviceConfig;
  };
in {
  options.modules.services.frp = with types; {
    package = mkOpt package pkgs.frp;
    user = mkOpt str "";
    tokenSecretName = mkOpt str "frp-token";
    restartSec = mkOpt str "5s";

    server = {
      enable = mkBoolOpt false;
      bindAddr = mkOpt str "0.0.0.0";
      bindPort = mkOpt (ints.between 1 65535) 7000;
      extraConfig = mkOpt attrs {};
      serviceConfig = mkOpt attrs {};
    };

    client = {
      enable = mkBoolOpt false;
      serverAddr = mkOpt str "";
      serverPort = mkOpt (ints.between 1 65535) 7000;
      proxies = mkOpt (listOf attrs) [];
      extraConfig = mkOpt attrs {};
      serviceConfig = mkOpt attrs {};
    };
  };

  config = mkIf (enabled && isLinux) (mkMerge [
    {
      assertions = [
        {
          assertion = builtins.hasAttr cfg.tokenSecretName config.age.secrets;
          message = "modules.services.frp token secret '${cfg.tokenSecretName}' must be defined in age.secrets";
        }
        {
          assertion = !cfg.client.enable || cfg.client.serverAddr != "";
          message = "modules.services.frp.client.serverAddr must be set";
        }
      ];

      environment.systemPackages = [ cfg.package ];
    }

    (mkIf cfg.server.enable {
      systemd.services.frps = mkService "frps" "FRP server" serverTemplate cfg.server.serviceConfig;
    })

    (mkIf cfg.client.enable {
      systemd.services.frpc = mkService "frpc" "FRP client" clientTemplate cfg.client.serviceConfig;
    })
  ]);
}
