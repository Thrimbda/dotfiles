{ hey, lib, config, pkgs, hostSystem ? null, ... }:

with lib;
with hey.lib;
let
  cfg = config.modules.desktop.audio.hdmi;
  system = if hostSystem != null then hostSystem else pkgs.stdenv.hostPlatform.system;
  isLinux = hasSuffix "-linux" system;
  mkSinkRule = sink: priority: {
    matches = [{ "node.name" = sink; }];
    actions.update-props = {
      "priority.driver" = priority;
      "priority.session" = priority;
    };
  };
  ensureAudio = pkgs.writeShellScript "${cfg.serviceName}-ensure" ''
    set -eu

    ${optionalString cfg.preventPulseaudioAutospawn ''
      # A real PulseAudio daemon can autospawn and hold HDMI before PipeWire.
      ${pkgs.procps}/bin/pkill -x pulseaudio || true
    ''}

    for _ in $(${pkgs.coreutils}/bin/seq 1 ${toString cfg.cardWaitAttempts}); do
      if ${pkgs.pulseaudio}/bin/pactl list short cards \
          | ${pkgs.gnugrep}/bin/grep -F -q ${escapeShellArg cfg.card}; then
        break
      fi
      ${pkgs.coreutils}/bin/sleep ${escapeShellArg cfg.cardWaitInterval}
    done

    ${pkgs.pulseaudio}/bin/pactl set-card-profile ${escapeShellArg cfg.card} off || true
    ${pkgs.pulseaudio}/bin/pactl set-card-profile ${escapeShellArg cfg.card} ${escapeShellArg cfg.profile}
    ${pkgs.pulseaudio}/bin/pactl set-default-sink ${escapeShellArg cfg.sink}
  '';
in {
  options.modules.desktop.audio.hdmi = with types; {
    enable = mkBoolOpt false;
    serviceName = mkOpt str "axiom-hdmi-audio";
    card = mkOpt str "";
    sink = mkOpt str "";
    profile = mkOpt str "output:hdmi-stereo";
    priority = mkOpt int 1100;
    lowPrioritySinks = mkOpt (listOf str) [];
    lowPriority = mkOpt int 100;
    preventPulseaudioAutospawn = mkBoolOpt true;
    cardWaitAttempts = mkOpt int 20;
    cardWaitInterval = mkOpt str "0.25";
    before = mkOpt (listOf str) [ "easyeffects.service" ];
  };

  config = mkIf (cfg.enable && isLinux) {
    assertions = [
      {
        assertion = cfg.card != "";
        message = "modules.desktop.audio.hdmi.card must be set";
      }
      {
        assertion = cfg.sink != "";
        message = "modules.desktop.audio.hdmi.sink must be set";
      }
    ];

    services.pipewire.wireplumber.extraConfig."51-hdmi-audio-priority" = {
      "monitor.alsa.rules" = [ (mkSinkRule cfg.sink cfg.priority) ]
        ++ map (sink: mkSinkRule sink cfg.lowPriority) cfg.lowPrioritySinks;
    };

    home.configFile."pulse/client.conf" = mkIf cfg.preventPulseaudioAutospawn {
      force = true;
      text = ''
        autospawn = no
      '';
    };

    systemd.user.services.${cfg.serviceName} = {
      wantedBy = [ "graphical-session.target" ];
      unitConfig = {
        Description = "Ensure HDMI audio output exists";
        After = [ "pipewire.service" "pipewire-pulse.service" "wireplumber.service" ];
        Wants = [ "pipewire.service" "pipewire-pulse.service" "wireplumber.service" ];
        Before = cfg.before;
        PartOf = [ "graphical-session.target" ];
      };
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${ensureAudio}";
      };
    };

    systemd.user.services.easyeffects.unitConfig = mkIf (elem "easyeffects.service" cfg.before) {
      After = mkAfter [ "${cfg.serviceName}.service" ];
      Wants = mkAfter [ "${cfg.serviceName}.service" ];
    };
  };
}
