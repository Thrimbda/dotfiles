{ config, lib, pkgs, ... }:
let
  relay = import ../../../config/frp/sunshine-relay.nix { inherit config lib pkgs; };
  acorn = (import ./_facts.nix).acorn;
  hyprctl = "${config.programs.hyprland.package}/bin/hyprctl";
  prepareDisplay = pkgs.writeShellScript "sunshine-prepare-display" ''
    set -eu
    if ! ${hyprctl} monitors -j | ${pkgs.jq}/bin/jq -e 'any(.[]; .name == "SUNSHINE")' >/dev/null; then
      ${hyprctl} output create headless SUNSHINE
    fi
    ${hyprctl} eval 'hl.monitor({output="SUNSHINE",mode="1920x1080@60",position="auto",scale=1})'
    ${hyprctl} eval 'hl.dispatch(hl.dsp.dpms({monitor="SUNSHINE",action="enable"}))'
    ${hyprctl} eval 'hl.dispatch(hl.dsp.focus({monitor="SUNSHINE"}))'
  '';
  proxy = type: port: {
    name = "axiom-sunshine-${type}-${toString port}";
    inherit type;
    localIP = "127.0.0.1";
    localPort = port;
    remotePort = port;
    transport.useCompression = false;
  };
in
{
  modules.desktop.hyprland.monitors = lib.mkAfter [
    {
      output = "SUNSHINE";
      mode = "1920x1080@60";
      position = "auto";
      scale = 1;
    }
  ];
  # Keep the virtual output rendering through both idle and lock-screen DPMS.
  # The session lock and physical displays retain their existing behaviour.
  modules.desktop.caelestia.extraShellPatches = [ ./caelestia-sunshine-dpms.patch ];

  services.sunshine = {
    enable = true;
    package = pkgs.sunshine.override { cudaSupport = true; };
    capSysAdmin = false;
    # The relay connects locally; the management UI stays on the host.
    openFirewall = false;
    autoStart = false;
    settings = {
      sunshine_name = "Axiom";
      # KMS cannot capture a headless output. Name selection survives hotplug.
      capture = "wlr";
      output_name = "SUNSHINE";
      encoder = "nvenc";
      upnp = "disabled";
      origin_web_ui_allowed = "pc";
      # A relay's local endpoint must not cause Internet streams to be treated
      # as trusted LAN traffic. Moonlight 6.1 supports encrypted video/audio.
      lan_encryption_mode = 2;
      wan_encryption_mode = 2;
    };
    applications.apps = [
      {
        name = "Axiom Desktop";
        image-path = "desktop.png";
        prep-cmd = [
          {
            do = "${prepareDisplay}";
          }
        ];
      }
    ];
  };

  # Start after UWSM has imported the real Wayland/PipeWire session environment.
  systemd.user.services.sunshine = {
    wantedBy = [ "hyprland-session.target" ];
    partOf = lib.mkForce [ "hyprland-session.target" ];
    after = lib.mkAfter [ "hyprland-session.target" ];
    serviceConfig.ExecStartPre = [ "${prepareDisplay}" ];
  };

  systemd.services.frpc-sunshine = lib.recursiveUpdate
    (relay.mkService "frpc" {
      inherit (relay) auth;
      serverAddr = acorn.publicIp;
      serverPort = relay.port;
      loginFailExit = false;
      transport = {
        # QUIC still uses reliable streams. v2 negotiates the compact UDP
        # binary codec in frp 0.71, avoiding JSON/base64 packet expansion.
        protocol = "quic";
        wireProtocol = "v2";
        tls = {
          enable = true;
          trustedCaFile = ../../../config/frp/acorn-frps.crt;
          serverName = acorn.publicIp;
        };
      };
      proxies = (map (proxy "tcp") relay.tcpPorts) ++ (map (proxy "udp") relay.udpPorts);
    })
    {
      after = [ "network-online.target" acorn.frpcDirectRouteUnit ];
      requires = [ acorn.frpcDirectRouteUnit ];
    };
}
