{ config, lib, pkgs, ... }:
let
  hyprctl = "${config.programs.hyprland.package}/bin/hyprctl";
  prepareDisplay = pkgs.writeShellScript "sunshine-prepare-display" ''
    set -eu
    if ! ${hyprctl} monitors -j | ${pkgs.jq}/bin/jq -e 'any(.[]; .name == "SUNSHINE")' >/dev/null; then
      ${hyprctl} output create headless SUNSHINE
    fi
    ${hyprctl} eval 'hl.monitor({output="SUNSHINE",mode="3840x2160@60",position="auto",scale=2})'
    ${hyprctl} eval 'hl.dispatch(hl.dsp.dpms({monitor="SUNSHINE",action="enable"}))'
    ${hyprctl} eval 'hl.dispatch(hl.dsp.focus({monitor="SUNSHINE"}))'
  '';
in
{
  modules.desktop.hyprland.monitors = lib.mkAfter [
    {
      output = "SUNSHINE";
      mode = "3840x2160@60";
      position = "auto";
      scale = 2;
    }
  ];
  # Keep the virtual output rendering through both idle and lock-screen DPMS.
  # The session lock and physical displays retain their existing behaviour.
  modules.desktop.caelestia.extraShellPatches = [ ./caelestia-sunshine-dpms.patch ];

  services.sunshine = {
    enable = true;
    package = pkgs.sunshine.override { cudaSupport = true; };
    capSysAdmin = false;
    # WireGuard opens only streaming ports; the management UI stays on the host.
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
      # Keep stream encryption enabled on the private desktop network.
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

}
