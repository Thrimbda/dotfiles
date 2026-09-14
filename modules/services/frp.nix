{ hey, lib, config, pkgs, hostSystem ? null, ... }:

with lib;
with hey.lib;
let
  cfg = config.modules.services.frp;
  system = if hostSystem != null then hostSystem else pkgs.stdenv.hostPlatform.system;
  isLinux = hasSuffix "-linux" system;
  isDarwin = hasSuffix "-darwin" system;
  enabled = cfg.server.enable || cfg.client.enable;
  user = if cfg.user != "" then cfg.user else config.user.name;
  secretNames = cfg.secretNames // { FRP_TOKEN = cfg.tokenSecretName; };
  secretPaths = pkgs.writeText "frp-secret-paths.json" (builtins.toJSON
    (mapAttrs (_: name: if isDarwin
      then "${config.age.secrets.${name}.file}"
      else config.age.secrets.${name}.path) secretNames));
  runtimeDir = name: if isDarwin
    then "${config.user.home}/Library/Application Support/${name}"
    else "/run/${name}";
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
  } // optionalAttrs (cfg.client.visitors != []) {
    visitors = cfg.client.visitors;
  });

  serverTemplate = toml.generate "frps.toml" serverSettings;
  clientTemplate = toml.generate "frpc.toml" clientSettings;

  mkRenderConfig = name: template: pkgs.writeShellScript "render-${name}-config" ''
    set -eu

    umask 077
    ${pkgs.coreutils}/bin/mkdir -p ${escapeShellArg (runtimeDir name)}
    exec ${pkgs.python3}/bin/python3 ${./frp/render-config.py} \
      ${template} ${secretPaths} ${escapeShellArg "${runtimeDir name}/${name}.toml"} \
      ${optionalString isDarwin "${pkgs.age}/bin/age ${escapeShellArg config.modules.agenix.sshKey}"}
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
    secretNames = mkOpt (attrsOf str) {};

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
      visitors = mkOpt (listOf attrs) [];
      darwinUserAgent = mkBoolOpt false;
      extraConfig = mkOpt attrs {};
      serviceConfig = mkOpt attrs {};
    };
  };

  config = mkIf enabled (mkMerge [
    {
      assertions = [
        {
          assertion = !isDarwin || !cfg.server.enable;
          message = "The FRP server is supported on Linux only";
        }
        {
          assertion = all (name: builtins.hasAttr name config.age.secrets) (attrValues secretNames);
          message = "Every modules.services.frp secret must be defined in age.secrets";
        }
        {
          assertion = !cfg.client.enable || cfg.client.serverAddr != "";
          message = "modules.services.frp.client.serverAddr must be set";
        }
      ];

      environment.systemPackages = [ cfg.package ];
    }

    (optionalAttrs isLinux (mkIf cfg.server.enable {
      systemd.services.frps = mkService "frps" "FRP server" serverTemplate cfg.server.serviceConfig;
    }))

    (optionalAttrs isLinux (mkIf cfg.client.enable {
      systemd.services.frpc = mkService "frpc" "FRP client" clientTemplate cfg.client.serviceConfig;
    }))

    (optionalAttrs isDarwin (mkIf cfg.client.enable {
      launchd = let job = {
        script = ''
          set -eu
          umask 077
          ${mkRenderConfig "frpc" clientTemplate}
          exec ${cfg.package}/bin/frpc -c ${escapeShellArg "${runtimeDir "frpc"}/frpc.toml"}
        '';
        serviceConfig = {
          RunAtLoad = true;
          KeepAlive = true;
          ThrottleInterval = 5;
          ProcessType = "Background";
          StandardOutPath = "/dev/null";
          StandardErrorPath = "${config.user.home}/Library/Logs/frpc-error.log";
          SoftResourceLimits.Core = 0;
          HardResourceLimits.Core = 0;
        } // optionalAttrs (!cfg.client.darwinUserAgent) { UserName = user; };
      }; in if cfg.client.darwinUserAgent
        then { user.agents.frpc = job; }
        else { daemons.frpc = job; };
    }))
  ]);
}
