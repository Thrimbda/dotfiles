{ lib, pkgs, ... }:

let
  stateDir = "/var/lib/acorn-traffic-accounting";
  services = [ "frps" "nginx" "rustdesk-relay" "sshd" ];

  sample = pkgs.writeShellApplication {
    name = "acorn-traffic-sample";
    runtimeInputs = [ pkgs.coreutils pkgs.curl pkgs.jq pkgs.systemd ];
    text = ''
      set -euo pipefail

      state_dir=${lib.escapeShellArg stateDir}
      sample_dir="$state_dir/samples"
      umask 0027
      install -d -m 0750 "$sample_dir"

      services_json=$(
        for service in ${lib.concatStringsSep " " services}; do
          ingress=$(systemctl show "$service" --property=IPIngressBytes --value 2>/dev/null || true)
          egress=$(systemctl show "$service" --property=IPEgressBytes --value 2>/dev/null || true)
          jq -cn \
            --arg service "$service" \
            --arg ingress "$ingress" \
            --arg egress "$egress" \
            '{($service): {
              ingressBytes: (try ($ingress | tonumber) catch null),
              egressBytes: (try ($egress | tonumber) catch null)
            }}'
        done | jq -cs 'add'
      )

      frps_response=$(curl --silent --fail --max-time 5 http://127.0.0.1:7500/api/proxy/tcp 2>/dev/null || true)
      if [ -n "$frps_response" ] && frps_json=$(printf '%s' "$frps_response" | jq -ce '{
        available: true,
        proxies: [
          .proxies[]? | {
            name,
            status,
            curConns,
            todayTrafficIn,
            todayTrafficOut
          }
        ]
      }'); then
        :
      else
        frps_json='{"available":false,"proxies":null}'
      fi

      timestamp=$(date --utc --iso-8601=seconds)
      sample_json=$(jq -cn \
        --arg timestamp "$timestamp" \
        --argjson services "$services_json" \
        --argjson frps "$frps_json" \
        '{timestamp: $timestamp, services: $services, frps: $frps}')

      sample_path=$(mktemp "$sample_dir/$(date --utc +%s).XXXXXX.json")
      printf '%s\n' "$sample_json" > "$sample_path"
      chmod 0640 "$sample_path"
    '';
  };

  report = pkgs.writeShellApplication {
    name = "acorn-traffic-report";
    runtimeInputs = [ pkgs.coreutils pkgs.findutils pkgs.jq ];
    text = ''
      set -euo pipefail

      state_dir=${lib.escapeShellArg stateDir}
      sample_dir="$state_dir/samples"

      if [ "$(id -u)" -ne 0 ]; then
        printf '%s\n' 'acorn-traffic-report must run as root' >&2
        exit 1
      fi

      if [ ! -d "$sample_dir" ]; then
        printf '%s\n' 'no traffic samples have been collected' >&2
        exit 1
      fi

      mapfile -t sample_names < <(find "$sample_dir" -maxdepth 1 -type f -name '*.json' -printf '%f\n' | sort)
      sample_count=''${#sample_names[@]}
      if [ "$sample_count" -lt 2 ]; then
        printf '%s\n' 'at least two samples are required' >&2
        exit 1
      fi

      previous="$sample_dir/''${sample_names[$((sample_count - 2))]}"
      current="$sample_dir/''${sample_names[$((sample_count - 1))]}"

      jq -rs '
        def delta($before; $after):
          if ($before == null or $after == null) then null
          elif $after < $before then "counter-reset"
          else $after - $before
          end;
        def format:
          if . == null then "unavailable"
          elif . == "counter-reset" then .
          elif . < 1024 then "\(.) B"
          elif . < 1048576 then "\((. / 1024 * 10 | floor) / 10) KiB"
          elif . < 1073741824 then "\((. / 1048576 * 10 | floor) / 10) MiB"
          else "\((. / 1073741824 * 10 | floor) / 10) GiB"
          end;
        .[0] as $previous |
        .[1] as $current |
        "interval: \($previous.timestamp) -> \($current.timestamp)",
        (($current.services | keys_unsorted[]) as $name |
          ($previous.services[$name] // {}) as $before |
          ($current.services[$name]) as $after |
          "service \($name): ingress=\(delta($before.ingressBytes; $after.ingressBytes) | format) egress=\(delta($before.egressBytes; $after.egressBytes) | format)"),
        (if $current.frps.available then
          ($current.frps.proxies[]? as $after |
            ([$previous.frps.proxies[]? | select(.name == $after.name)][0] // {}) as $before |
            "frps proxy \($after.name): ingress=\(delta($before.todayTrafficIn; $after.todayTrafficIn) | format) egress=\(delta($before.todayTrafficOut; $after.todayTrafficOut) | format) connections=\($after.curConns) status=\($after.status)"
          )
        else
          "frps proxy counters unavailable in current sample"
        end)' "$previous" "$current"
    '';
  };
in {
  modules.services.frp.server.serviceConfig.IPAccounting = true;
  modules.services.ssh.serviceConfig.IPAccounting = true;
  systemd.services.nginx.serviceConfig.IPAccounting = true;
  systemd.services.rustdesk-relay.serviceConfig.IPAccounting = true;

  systemd.tmpfiles.rules = [
    "d ${stateDir} 0750 root root -"
    "d ${stateDir}/samples 0750 root root 30d"
  ];

  systemd.services.acorn-traffic-sample = {
    description = "Capture Acorn local traffic attribution counters";
    after = [ "network-online.target" "frps.service" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      UMask = "0027";
      ExecStart = "${sample}/bin/acorn-traffic-sample";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      ReadWritePaths = [ stateDir ];
    };
  };

  systemd.timers.acorn-traffic-sample = {
    description = "Periodically capture Acorn traffic attribution counters";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "5min";
      Persistent = true;
      Unit = "acorn-traffic-sample.service";
    };
  };

  environment.systemPackages = [ report ];
}
