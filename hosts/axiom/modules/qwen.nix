{ config, lib, pkgs, ... }:

let
  userName = config.user.name;
  llamaCppBase = pkgs.unstable.llama-cpp.override { cudaSupport = true; };
  llamaCpp = llamaCppBase.overrideAttrs (_finalAttrs: previousAttrs: {
    version = "10472";
    src = pkgs.fetchFromGitHub {
      owner = "ggml-org";
      repo = "llama.cpp";
      rev = "b10472";
      hash = "sha256-Wm3Nnl3AUr0YMDGRjV3vK8qAcp4dCMyg1A7SMD4LJRg=";
    };
    npmDepsHash = "sha256-2Q7XhaLAArmviOLdQsNbYTfdyDE5pW9lR26cRHEVl9k=";
    preConfigure = builtins.replaceStrings
      [ "$(cat COMMIT)" ]
      [ "60eeeb6" ]
      previousAttrs.preConfigure;
  });
  qwenModelDir = "${config.user.home}/.local/share/models/qwen3.8-27b";
  qwenQ4Model = "${qwenModelDir}/RVN-Q4_K_M-mtp.gguf";
  qwenQ6Model = "${qwenModelDir}/RVN-Q6_K-mtp.gguf";
  qwenModel = "${qwenModelDir}/active.gguf";
  qwenChatTemplate = "${qwenModelDir}/chat_template.jinja";
  qwenService = "qwen3-8-27b.service";
  qwenSudo = "/run/wrappers/bin/sudo";
  qwenEnsureModel = pkgs.writeShellScript "qwen-ensure-model" ''
    set -eu
    if [ ! -e ${lib.escapeShellArg qwenModel} ] && [ ! -L ${lib.escapeShellArg qwenModel} ]; then
      ${pkgs.coreutils}/bin/ln -s ${lib.escapeShellArg qwenQ4Model} ${lib.escapeShellArg qwenModel}
    fi
    if [ ! -L ${lib.escapeShellArg qwenModel} ]; then
      echo "${qwenModel} must be a symbolic link" >&2
      exit 1
    fi
    if [ ! -f ${lib.escapeShellArg qwenModel} ]; then
      echo "selected Qwen model is unavailable: ${qwenModel}" >&2
      exit 1
    fi
  '';
  qwenModelControl = pkgs.writeShellApplication {
    name = "qwen-model";
    runtimeInputs = with pkgs; [ coreutils curl systemd ];
    text = ''
      service=${lib.escapeShellArg qwenService}
      active=${lib.escapeShellArg qwenModel}
      q4=${lib.escapeShellArg qwenQ4Model}
      q6=${lib.escapeShellArg qwenQ6Model}
      health=http://127.0.0.1:8081/health

      wait_healthy() {
        attempt=0
        while [ "$attempt" -lt 90 ]; do
          if systemctl is-active --quiet "$service" && curl --fail --silent --max-time 2 "$health" >/dev/null; then
            return 0
          fi
          if systemctl is-failed --quiet "$service"; then
            return 1
          fi
          sleep 2
          attempt=$((attempt + 1))
        done
        return 1
      }

      print_status() {
        resolved=$(readlink -f "$active" 2>/dev/null || true)
        case "$resolved" in
          "$q4") selected=q4 ;;
          "$q6") selected=q6 ;;
          "") selected=none ;;
          *) selected=invalid ;;
        esac
        printf 'selected: %s\n' "$selected"
        printf 'target: %s\n' "''${resolved:-unavailable}"
        printf 'service: %s\n' "$(systemctl is-active "$service" 2>/dev/null || true)"
        if curl --fail --silent --max-time 2 "$health" >/dev/null; then
          printf 'health: ok\n'
        else
          printf 'health: unavailable\n'
        fi
      }

      atomic_link() {
        target=$1
        temporary="$active.new.$$"
        rm -f -- "$temporary"
        ln -s -- "$target" "$temporary"
        mv -Tf -- "$temporary" "$active"
      }

      restart_selected() {
        ${qwenSudo} systemctl restart "$service"
        if ! wait_healthy; then
          systemctl status "$service" --no-pager >&2 || true
          return 1
        fi
      }

      select_model() {
        target=$1
        label=$2
        if [ ! -f "$target" ]; then
          printf 'model is unavailable: %s\n' "$target" >&2
          return 1
        fi

        previous=$(readlink -f "$active" 2>/dev/null || true)
        if [ "$previous" = "$target" ] && systemctl is-active --quiet "$service" && curl --fail --silent --max-time 2 "$health" >/dev/null; then
          printf '%s is already selected and healthy\n' "$label"
          print_status
          return 0
        fi

        ${qwenSudo} -v
        atomic_link "$target"
        if restart_selected; then
          printf 'switched to %s\n' "$label"
          print_status
          return 0
        fi

        printf 'failed to start %s; restoring previous selection\n' "$label" >&2
        if [ -n "$previous" ] && [ -f "$previous" ]; then
          atomic_link "$previous"
          if restart_selected; then
            printf 'restored previous model: %s\n' "$previous" >&2
          else
            printf 'failed to restore previous model: %s\n' "$previous" >&2
          fi
        fi
        return 1
      }

      case "''${1:-}" in
        q4) select_model "$q4" q4 ;;
        q6) select_model "$q6" q6 ;;
        start)
          ${qwenSudo} systemctl start "$service"
          wait_healthy
          print_status
          ;;
        stop)
          ${qwenSudo} systemctl stop "$service"
          print_status
          ;;
        restart)
          restart_selected
          print_status
          ;;
        status) print_status ;;
        *)
          printf 'usage: qwen-model {q4|q6|start|stop|restart|status}\n' >&2
          exit 2
          ;;
      esac
    '';
  };
  qwenBaseArgs = [
    "--model" qwenModel
    "--jinja"
    "--chat-template-file" qwenChatTemplate
    "--alias" "qwen3.8-27b-uncensored"
    "--host" "127.0.0.1"
    "--port" "8081"
    "--no-ui"
    "--flash-attn" "on"
    "--parallel" "1"
    "--spec-type" "draft-mtp"
    "--spec-draft-n-max" "2"
    "--chat-template-kwargs" ''{"reasoning_effort":"medium"}''
  ];
  qwenQ4Args = [
    "--ctx-size" "262144"
    "--cache-type-k" "q8_0"
    "--cache-type-v" "q8_0"
    "--n-gpu-layers" "all"
  ];
  qwenQ6Args = [
    "--ctx-size" "131072"
    "--cache-type-k" "q4_0"
    "--cache-type-v" "q4_0"
    "--n-gpu-layers" "all"
  ];
  qwenLauncher = pkgs.writeShellScript "qwen-launcher" ''
    set -eu
    active=${lib.escapeShellArg qwenModel}
    q4=${lib.escapeShellArg qwenQ4Model}
    q6=${lib.escapeShellArg qwenQ6Model}

    case "$(${pkgs.coreutils}/bin/readlink -f "$active")" in
      "$q4")
        exec ${llamaCpp}/bin/llama-server ${lib.escapeShellArgs (qwenBaseArgs ++ qwenQ4Args)}
        ;;
      "$q6")
        exec ${llamaCpp}/bin/llama-server ${lib.escapeShellArgs (qwenBaseArgs ++ qwenQ6Args)}
        ;;
      *)
        echo "selected Qwen model is not a supported target: $active" >&2
        exit 1
        ;;
    esac
  '';
in
{
  environment.systemPackages = [ qwenModelControl ];

  systemd.services.qwen3-8-27b = {
    description = "Qwen3.8 27B uncensored inference server";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    unitConfig.ConditionPathExists = qwenChatTemplate;
    serviceConfig = {
      Type = "simple";
      User = userName;
      WorkingDirectory = qwenModelDir;
      ExecStartPre = qwenEnsureModel;
      ExecStart = qwenLauncher;
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
