{ hey, lib, config, pkgs, hostSystem ? null, ... }:

with lib;
with hey.lib;
let
  cfg = config.modules.services.healthchecks;
  system = if hostSystem != null then hostSystem else pkgs.stdenv.hostPlatform.system;
  isLinux = hasSuffix "-linux" system;
  enabledChecks = filterAttrs (_: check: check.enable) cfg.checks;
  mkCheckScript = name: check: pkgs.writeShellScript "${name}-runner" ''
    set -eu

    state_dir=${escapeShellArg "/run/${check.runtimeDirectory}"}
    counter="$state_dir/${check.stateFile}"
    threshold=${toString check.threshold}

    ${pkgs.coreutils}/bin/mkdir -p "$state_dir"

    status=0
    (
      ${check.check}
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
        check = mkOpt lines "";
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
