{ lib, config, pkgs, ... }:

with lib;
let
  facts = import ./_facts.nix;
  acorn = facts.acorn;
  relay = facts.ant;
  legionPiProfile = "${config.home.dataDir}/legion-pi/profile";
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
    export PI_CODING_AGENT_DIR="${legionPiProfile}/agent"
    export PI_CODING_AGENT_SESSION_DIR="${legionPiProfile}/sessions"
    export PI_SUBAGENT_PI_BINARY="${config.home.binDir}/pi"
    export PI_LENS_HOME="${legionPiProfile}/.legionmind/pi-lens"
  '';

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
    };
  };

  systemd.services.frpc-ant-direct-route = {
    description = "Route Axiom frpc traffic to Ant outside Clash Meta";
    after = [ "network-online.target" "clash-verge.service" ];
    wants = [ "network-online.target" ];
    before = [ "frpc.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.iproute2 ];
    serviceConfig.Type = "oneshot";
    script = ''
      set -eu

      priority=${toString relay.frpcDirectRoutePriority}
      target=${relay.publicIp}/32

      ip -4 rule del priority "$priority" 2>/dev/null || true
      ip -4 rule add priority "$priority" to "$target" lookup main
      ip -4 route flush cache || true
    '';
  };

  systemd.services.frpc = {
    after = [
      relay.frpcDirectRouteUnit
      "auth-mini-gateway-status-axiom.service"
      "auth-mini-gateway-opencode-axiom.service"
    ];
    wants = [
      relay.frpcDirectRouteUnit
      "auth-mini-gateway-status-axiom.service"
      "auth-mini-gateway-opencode-axiom.service"
    ];
    requires = [ relay.frpcDirectRouteUnit ];
  };

  modules.services.frp.client = {
    enable = true;
    serverAddr = relay.publicIp;
    extraConfig.transport.tls = {
      enable = true;
      trustedCaFile = ../../../config/frp/ant-frps.crt;
      serverName = relay.publicIp;
    };
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
    ];
  };
}
