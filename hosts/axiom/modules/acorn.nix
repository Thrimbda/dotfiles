{ lib, config, pkgs, ... }:

with lib;
let
  facts = import ./_facts.nix;
  acorn = facts.acorn;
  userName = config.user.name;
  legionPiProfile = "${config.home.dataDir}/legion-pi/profile";
  piWebDataDir = "${config.home.dataDir}/legion-pi/pi-web";
  piWebUserManagerUnit = "user@${toString config.users.users.${userName}.uid}.service";
  gatewayEnvironment = {
    GATEWAY_MAX_DOWNSTREAM_CONNECTIONS = "256";
    GATEWAY_MAX_ACTIVE_UPSTREAMS = "128";
    GATEWAY_MAX_BLOCKING_RESOLVERS = "8";
    TRUSTED_PROXY_CIDRS = "";
    SESSION_ABSOLUTE_TTL_SECONDS = "2592000";
    SESSION_TOUCH_INTERVAL_SECONDS = "3600";
  };
in {
  networking.hosts.${acorn.publicIp} = [ "constx.0xc1.wang" ];

  modules.shell.zsh.envInit = mkAfter ''
    export PATH="${legionPiProfile}/runtime/node_modules/.bin:$PATH"
    export PI_CODING_AGENT_DIR="${legionPiProfile}/agent"
    export PI_CODING_AGENT_SESSION_DIR="${legionPiProfile}/sessions"
    export PI_SUBAGENT_PI_BINARY="${legionPiProfile}/runtime/node_modules/.bin/pi"
    export PI_LENS_HOME="${legionPiProfile}/.legionmind/pi-lens"
    export PI_WEB_DATA_DIR="${piWebDataDir}"
    export PI_WEB_HOST="127.0.0.1"
    export PI_WEB_PORT="8504"
  '';

  assertions = [{
    assertion = all (port: !(elem port config.networking.firewall.allowedTCPPorts)) [ 7782 8504 ];
    message = "axiom PI WEB and auth gateway ports must remain closed in the host firewall";
  }];

  modules.services.auth-mini-gateway = {
    enable = true;
    instances = {
      status-axiom = {
        publicHost = "status-axiom.0xc1.wang";
        port = 7779;
        upstreamUrl = "http://127.0.0.1:8080";
        upstreamProtocol = "http1";
        dependencies = [ "gatus.service" ];
        stateDirectory = "auth-mini-gateway-status-axiom";
        extraEnvironment = gatewayEnvironment;
      };
      opencode-axiom = {
        publicHost = "opencode-axiom.0xc1.wang";
        port = 7780;
        upstreamUrl = "http://127.0.0.1:4096";
        upstreamProtocol = "http1";
        dependencies = [ "opencode-server.service" ];
        stateDirectory = "auth-mini-gateway-opencode-axiom";
        extraEnvironment = gatewayEnvironment;
      };
      pi-axiom = {
        publicHost = "pi-axiom.0xc1.wang";
        port = 7782;
        upstreamUrl = "http://127.0.0.1:8504";
        upstreamProtocol = "http1";
        dependencies = [ piWebUserManagerUnit ];
        stateDirectory = "auth-mini-gateway-pi-axiom";
        extraEnvironment = gatewayEnvironment;
      };
    };
  };

  systemd.services.frpc-acorn-direct-route = {
    description = "Route Axiom frpc traffic to acorn outside Clash Meta";
    after = [ "network-online.target" "clash-verge.service" ];
    wants = [ "network-online.target" ];
    before = [ "frpc.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.iproute2 ];
    serviceConfig.Type = "oneshot";
    script = ''
      set -eu

      priority=${toString acorn.frpcDirectRoutePriority}
      target=${acorn.publicIp}/32

      ip -4 rule del priority "$priority" 2>/dev/null || true
      ip -4 rule add priority "$priority" to "$target" lookup main
      ip -4 route flush cache || true
    '';
  };

  systemd.services.frpc = {
    after = [
      acorn.frpcDirectRouteUnit
      "auth-mini-gateway-status-axiom.service"
      "auth-mini-gateway-opencode-axiom.service"
      "auth-mini-gateway-pi-axiom.service"
    ];
    wants = [
      acorn.frpcDirectRouteUnit
      "auth-mini-gateway-status-axiom.service"
      "auth-mini-gateway-opencode-axiom.service"
      "auth-mini-gateway-pi-axiom.service"
    ];
    requires = [ acorn.frpcDirectRouteUnit ];
  };

  modules.services.frp.client = {
    enable = true;
    serverAddr = acorn.publicIp;
    proxies = [
      {
        name = "axiom-ssh";
        type = "tcp";
        localIP = "127.0.0.1";
        localPort = 22;
        remotePort = 2225;
      }
      {
        name = "axiom-gatus-http";
        type = "tcp";
        localIP = "127.0.0.1";
        localPort = 7779;
        remotePort = 18080;
      }
      {
        name = "axiom-opencode-http";
        type = "tcp";
        localIP = "127.0.0.1";
        localPort = 7780;
        remotePort = 18081;
      }
      {
        name = "axiom-pi-web-http";
        type = "tcp";
        localIP = "127.0.0.1";
        localPort = 7782;
        remotePort = 18082;
      }
    ];
  };
}
