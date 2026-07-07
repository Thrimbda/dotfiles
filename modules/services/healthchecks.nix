{ hey, lib, config, pkgs, hostSystem ? null, ... }:

with lib;
with hey.lib;
let
  cfg = config.modules.services.healthchecks;
  system = if hostSystem != null then hostSystem else pkgs.stdenv.hostPlatform.system;
  isLinux = hasSuffix "-linux" system;
  enabledChecks = filterAttrs (_: check: check.enable) cfg.checks;
  mkPredicate = check:
    if check.check != null then check.check
    else if check.http.url != null then ''
      ${pkgs.curl}/bin/curl --fail --silent --show-error --max-time ${toString check.http.maxTime} ${escapeShellArg check.http.url} >/dev/null
    ''
    else if check.serviceCore.enable then ''
      healthy=false
      if ${pkgs.systemd}/bin/systemctl is-active --quiet ${escapeShellArg check.serviceCore.service}; then
        main_pid="$(${pkgs.systemd}/bin/systemctl show -P MainPID ${escapeShellArg check.serviceCore.service} 2>/dev/null || printf '0')"
        ${optionalString (check.serviceCore.childPattern != null) ''
          if [ "$main_pid" != "0" ] \
              && ${pkgs.procps}/bin/pgrep -P "$main_pid" -f ${escapeShellArg check.serviceCore.childPattern} >/dev/null 2>&1; then
            healthy=true
          fi
        ''}
        ${concatMapStringsSep "\n" (interface: ''
          if ${pkgs.iproute2}/bin/ip link show ${escapeShellArg interface} >/dev/null 2>&1; then
            healthy=true
          fi
        '') check.serviceCore.interfaces}
      fi

      if [ "$healthy" = true ]; then
        exit 0
      fi

      exit 1
    ''
    else ''
      printf 'healthcheck has no predicate configured\n' >&2
      exit 1
    '';
  mkCheckScript = name: check: pkgs.writeShellScript "${name}-runner" ''
    set -eu

    state_dir=${escapeShellArg "/run/${check.runtimeDirectory}"}
    counter="$state_dir/${check.stateFile}"
    threshold=${toString check.threshold}

    ${pkgs.coreutils}/bin/mkdir -p "$state_dir"

    status=0
    (
      ${mkPredicate check}
    ) || status=$?

    if [ "$status" -eq 0 ]; then
      ${pkgs.coreutils}/bin/rm -f "$counter"
      exit 0
    fi

    failures=0
    if [ -s "$counter" ]; then
      failures="$(${pkgs.coreutils}/bin/cat "$counter" 2>/dev/null || printf '0')"
    fi
    case "$failures" in
      ""|*[!0-9]*) failures=0 ;;
    esac
    failures=$((failures + 1))
    printf '%s\n' "$failures" > "$counter"
    printf '%s (%s/%s)\n' ${escapeShellArg check.failureMessage} "$failures" "$threshold" >&2

    if [ "$failures" -ge "$threshold" ]; then
      ${pkgs.coreutils}/bin/rm -f "$counter"
      ${optionalString (check.restartUnit != "") ''
        ${pkgs.systemd}/bin/systemctl restart ${escapeShellArg check.restartUnit}
      ''}
      exit 1
    fi
  '';
in {
  options.modules.services.healthchecks = with types; {
    checks = mkOpt (attrsOf (submodule ({ name, ... }: {
      options = {
        enable = mkBoolOpt true;
        description = mkOpt str "${name} health check";
        check = mkOpt (nullOr lines) null;
        threshold = mkOpt int 3;
        failureMessage = mkOpt str "${name} health check failed";
        restartUnit = mkOpt str "";
        runtimeDirectory = mkOpt str "healthchecks";
        stateFile = mkOpt str "${name}.failures";
        after = mkOpt (listOf str) [];
        wants = mkOpt (listOf str) [];
        onBootSec = mkOpt str "2m";
        onUnitActiveSec = mkOpt str "1m";
        randomizedDelaySec = mkOpt str "15s";
        http = {
          url = mkOpt (nullOr str) null;
          maxTime = mkOpt int 5;
        };
        serviceCore = {
          enable = mkBoolOpt false;
          service = mkOpt str "";
          childPattern = mkOpt (nullOr str) null;
          interfaces = mkOpt (listOf str) [];
        };
      };
    }))) {};
  };

  config = mkIf isLinux {
    systemd.services = mapAttrs (_: check: {
      description = check.description;
      after = check.after;
      wants = check.wants;
      serviceConfig = {
        Type = "oneshot";
        RuntimeDirectory = check.runtimeDirectory;
        RuntimeDirectoryPreserve = "yes";
        ExecStart = "${mkCheckScript check.stateFile check}";
      };
    }) enabledChecks;

    systemd.timers = mapAttrs (name: check: {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = check.onBootSec;
        OnUnitActiveSec = check.onUnitActiveSec;
        RandomizedDelaySec = check.randomizedDelaySec;
        Unit = "${name}.service";
      };
    }) enabledChecks;
  };
}
