{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
let
  enabled = elem "bluetooth" config.modules.profiles.hardware;
  bluemanRuntime = pkgs.blueman.override { withPulseAudio = false; };
  bluemanSchemaDir = pkgs.glib.getSchemaPath bluemanRuntime;
  pythonPath = with pkgs.python3Packages; [
    bluemanRuntime
    pygobject3
    pycairo
  ];
  pythonModulePath = makeSearchPath pkgs.python3.sitePackages pythonPath;

  bluemanAuthAgent = pkgs.stdenvNoCC.mkDerivation {
    pname = "blueman-auth-agent";
    version = "2.4.6";
    dontUnpack = true;
    strictDeps = true;

    nativeBuildInputs = [
      pkgs.python3
      pkgs.wrapGAppsHook3
    ];
    buildInputs = [
      pkgs.gtk3
      pkgs.librsvg
      pkgs.adwaita-icon-theme
    ];
    installPhase = ''
      runHook preInstall
      install -D -m 0755 ${./bluetooth-auth-agent.py} "$out/bin/blueman-auth-agent"
      patchShebangs --build "$out/bin/blueman-auth-agent"
      runHook postInstall
    '';

    preFixup = ''
      gappsWrapperArgs+=(--prefix PYTHONPATH : ${pythonModulePath})
    '';

    meta = {
      description = "Private, authentication-only BlueZ Agent1 runner";
      license = licenses.gpl3Only;
      mainProgram = "blueman-auth-agent";
      platforms = platforms.linux;
    };
  };

  mkBluetoothRfkillFinalize = {
    name ? "bluetooth-rfkill-finalize",
    rfkillSysfs,
    rfkillCommand,
  }: pkgs.writeTextFile {
    inherit name;
    executable = true;
    text = builtins.replaceStrings
      [ "@rfkillSysfs@" "@rfkillCommand@" ]
      [ rfkillSysfs rfkillCommand ]
      (builtins.readFile ./bluetooth-rfkill-finalize.sh);
  };

  bluetoothRfkillFinalize = mkBluetoothRfkillFinalize {
    rfkillSysfs = "/sys/class/rfkill";
    rfkillCommand = "${pkgs.util-linux}/bin/rfkill";
  };

  bluemanAuthAgentTests = pkgs.runCommand "blueman-auth-agent-tests" {
    nativeBuildInputs = [
      pkgs.binutils
      pkgs.dbus
      pkgs.findutils
      pkgs.gnugrep
      pkgs.gobject-introspection
      pkgs.python3
      pkgs.python3Packages.pycairo
      pkgs.python3Packages.pygobject3
      pkgs.xvfb-run
    ];
    buildInputs = [
      pkgs.gtk3
      pkgs.librsvg
      pkgs.adwaita-icon-theme
    ];
    PYTHONPATH = pythonModulePath;
    GI_TYPELIB_PATH = makeSearchPath "lib/girepository-1.0" [
      pkgs.glib
      pkgs.gtk3
      pkgs.gdk-pixbuf
      pkgs.pango
      pkgs.atk
    ];
    GSETTINGS_SCHEMA_DIR = bluemanSchemaDir;
    XDG_DATA_DIRS = makeSearchPath "share" [
      pkgs.gtk3
      pkgs.gsettings-desktop-schemas
      pkgs.adwaita-icon-theme
      pkgs.hicolor-icon-theme
    ];
  } ''
    ${pkgs.python3}/bin/python ${./tests/test-bluetooth-auth-agent.py} \
      ${./bluetooth-auth-agent.py}

    mkdir -p "$TMPDIR/home"
    integration_log="$TMPDIR/auth-agent-integration.log"
    set +e
    HOME="$TMPDIR/home" GDK_BACKEND=x11 NO_AT_BRIDGE=1 \
      PYTHONWARNINGS=ignore::DeprecationWarning \
      ${pkgs.xvfb-run}/bin/xvfb-run -a \
      ${pkgs.python3}/bin/python ${./tests/test-bluetooth-auth-agent-integration.py} \
        ${./bluetooth-auth-agent.py} \
        ${hey.inputs.caelestia-shell}/services/Notifs.qml \
        ${bluemanAuthAgent}/bin/blueman-auth-agent \
        ${pkgs.dbus}/share/dbus-1/session.conf \
        > "$integration_log" 2>&1
    integration_status=$?
    set -e
    for sentinel in \
      PIN2468 135790 654321 123456 456789 \
      AA:BB:CC:DD:EE:FF /org/bluez/hci0/dev_AA_BB_CC_DD_EE_FF; do
      if ${pkgs.gnugrep}/bin/grep -Fq "$sentinel" "$integration_log"; then
        printf 'sensitive pairing sentinel leaked into integration output\n' >&2
        exit 1
      fi
    done
    cat "$integration_log"
    if [ "$integration_status" -ne 0 ]; then
      exit "$integration_status"
    fi

    public="$(${pkgs.findutils}/bin/find ${bluemanAuthAgent}/bin \
      -mindepth 1 -maxdepth 1 ! -name '.*' -printf '%f\n')"
    if [ "$public" != blueman-auth-agent ]; then
      printf 'unexpected public auth-agent executables:\n%s\n' "$public" >&2
      exit 1
    fi
    if [ ! -x ${bluemanAuthAgent}/bin/blueman-auth-agent ]; then
      printf 'auth-agent runner is not executable\n' >&2
      exit 1
    fi
    for entry in ${bluemanAuthAgent}/*; do
      case "''${entry##*/}" in
        bin|nix-support) ;;
        *)
          printf 'unexpected auth-agent output path: %s\n' "''${entry##*/}" >&2
          exit 1
          ;;
      esac
    done
    if ${pkgs.findutils}/bin/find ${bluemanAuthAgent}/bin -mindepth 1 -maxdepth 1 \
        -name '.*' ! -name '.*blueman-auth-agent*' -print -quit \
        | ${pkgs.gnugrep}/bin/grep -q .; then
      printf 'unrelated hidden wrapper leaked into the auth-agent package\n' >&2
      exit 1
    fi

    for forbidden in \
      etc \
      share/applications \
      share/Thunar \
      share/dbus-1 \
      lib/systemd \
      share/systemd \
      libexec; do
      if [ -e "${bluemanAuthAgent}/$forbidden" ]; then
        printf 'forbidden auth-agent surface: %s\n' "$forbidden" >&2
        exit 1
      fi
    done

    if ${pkgs.findutils}/bin/find ${bluemanAuthAgent}/bin -mindepth 1 -maxdepth 1 \
        -printf '%f\n' \
        | ${pkgs.gnugrep}/bin/grep -Eiq \
          'blueman-(applet|tray|manager|adapters|sendto|services|mechanism)'; then
      printf 'stock Blueman executable leaked into the auth-agent package\n' >&2
      exit 1
    fi

    wrapper_strings="$TMPDIR/auth-agent-wrapper-strings"
    : > "$wrapper_strings"
    while IFS= read -r wrapper; do
      ${pkgs.binutils}/bin/strings "$wrapper" >> "$wrapper_strings"
    done < <(${pkgs.findutils}/bin/find ${bluemanAuthAgent}/bin -maxdepth 1 -type f -print)
    if ${pkgs.gnugrep}/bin/grep -Fq '${bluemanRuntime}/bin' "$wrapper_strings"; then
      printf 'private Blueman bin leaked into runner PATH\n' >&2
      exit 1
    fi
    if ${pkgs.gnugrep}/bin/grep -Eiq \
        'blueman-(applet|tray|manager|adapters|sendto|services|mechanism)' \
        "$wrapper_strings"; then
      printf 'stock Blueman command leaked into runner wrapper environment\n' >&2
      exit 1
    fi
    if ! ${pkgs.gnugrep}/bin/grep -Fq \
        '${bluemanRuntime}/${pkgs.python3.sitePackages}' "$wrapper_strings"; then
      printf 'private Blueman Python runtime missing from runner wrapper\n' >&2
      exit 1
    fi
    if [ -s ${bluemanAuthAgent}/nix-support/propagated-user-env-packages ]; then
      printf 'auth-agent package propagates a user environment\n' >&2
      exit 1
    fi

    mkdir -p "$out"
    touch "$out/passed"
  '';

  bluetoothRfkillTests = pkgs.runCommand "bluetooth-rfkill-finalize-tests" {
    nativeBuildInputs = [
      pkgs.gnugrep
      pkgs.gnused
      pkgs.diffutils
      pkgs.python3
    ];
  } ''
    set -euo pipefail

    ${pkgs.bash}/bin/bash ${./tests/test-bluetooth-rfkill.sh} \
      ${./bluetooth-rfkill-finalize.sh} \
      ${./tests/fake-rfkill.sh}
    ${pkgs.python3}/bin/python ${./tests/test-systemd-rfkill-reactivation.py} \
      ${./bluetooth-rfkill-finalize.sh} \
      ${./tests/fake-rfkill.sh}

    vendor_unit=
    for candidate in \
      ${pkgs.systemd}/lib/systemd/system/systemd-rfkill.service \
      ${pkgs.systemd}/example/systemd/system/systemd-rfkill.service \
      ${pkgs.systemd}/share/systemd/system/systemd-rfkill.service; do
      if [ -f "$candidate" ]; then
        if [ -n "$vendor_unit" ]; then
          printf 'multiple upstream systemd-rfkill vendor units found\n' >&2
          exit 1
        fi
        vendor_unit=$candidate
      fi
    done
    if [ -z "$vendor_unit" ]; then
      printf 'upstream systemd-rfkill vendor unit is missing\n' >&2
      exit 1
    fi

    set +e
    ${pkgs.gnugrep}/bin/grep -Eq '^[[:space:]]*ExecStopPost=' "$vendor_unit"
    grep_status=$?
    set -e
    case "$grep_status" in
      0)
        printf 'upstream systemd-rfkill.service gained ExecStopPost; re-review required\n' >&2
        exit 1
        ;;
      1) ;;
      *)
        printf 'unable to audit upstream systemd-rfkill.service\n' >&2
        exit 1
        ;;
    esac
    ${pkgs.gnugrep}/bin/grep -Eq '^[[:space:]]*ExecStart=' "$vendor_unit"
    printf 'systemd-rfkill-vendor-audit: path=%s result=no-exec-stop-post\n' "$vendor_unit"

    mkdir -p "$out"
    touch "$out/passed"
  '';

  mkBluemanAuthAgentService = user: {
    description = "Private Bluetooth authentication agent";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    conflicts = [
      "blueman-applet.service"
      "blueman-manager.service"
      "app-blueman@autostart.service"
    ];
    unitConfig.ConditionUser = user;
    environment.GSETTINGS_SCHEMA_DIR = bluemanSchemaDir;
    serviceConfig = {
      Type = "notify";
      NotifyAccess = "main";
      ExecStart = "${bluemanAuthAgent}/bin/blueman-auth-agent";
      Restart = "on-failure";
      RestartSec = 2;
      TimeoutStartSec = 45;
    };
  };

  mkBluetoothRfkillProjection = { tlpEnabled, finalizer }:
    let
      restartHelper =
        "${pkgs.systemd}/bin/systemctl --no-block restart bluetooth-rfkill-unblock.service";
      helperService = {
        description = "Clear Bluetooth rfkill soft blocks";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${finalizer}";
        };
      };
    in {
      bootHelperService = helperService // {
        wantedBy = [ "multi-user.target" ];
        after = optional tlpEnabled "tlp.service";
      };
      eventHelperService = helperService // {
        description = "Clear Bluetooth rfkill soft blocks for %I";
        after = optional tlpEnabled "tlp.service";
      };
      udevRule = ''
        ACTION=="add", SUBSYSTEM=="rfkill", ATTR{type}=="bluetooth", TAG+="systemd", ENV{SYSTEMD_WANTS}+="${
          if tlpEnabled
          then "bluetooth-rfkill-unblock@%k.service"
          else "systemd-rfkill.service"
        }"
      '';
      resumeCommands = optionalString (!tlpEnabled) ''
        ${restartHelper}
      '';
      tlpSleepPostStop = optionalString tlpEnabled ''
        ${restartHelper}
      '';
    };

  rfkillProjection = mkBluetoothRfkillProjection {
    tlpEnabled = config.services.tlp.enable;
    finalizer = bluetoothRfkillFinalize;
  };

  bluetoothPredeployVmTest = pkgs.callPackage ./tests/_bluetooth-predeploy-vm-test.nix {
    authService = mkBluemanAuthAgentService "fixture";
    rfkillProjectionFactory = mkBluetoothRfkillProjection;
    caelestiaPackage = hey.inputs.caelestia-shell.packages.${pkgs.stdenv.hostPlatform.system}.with-cli;
    finalizerSource = ./bluetooth-rfkill-finalize.sh;
  };

in
mkIf enabled (mkMerge [
  {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          JustWorksRepairing = "always";
          MultiProfile = "multiple";
          Experimental = true;
        };
        Policy.AutoEnable = true;
      };
      disabledPlugins = [ "sap" ];
    };

    boot.kernelModules = [ "btusb" ];

    assertions = [{
      assertion = config.user.name != "";
      message = "The Bluetooth authentication agent requires config.user.name";
    }];

    # BlueZ and its CLI remain public. The full Blueman runtime is only a
    # private Python/data dependency of bluemanAuthAgent.
    environment.systemPackages = [ pkgs.bluez ];

    systemd.user.services.blueman-auth-agent = mkBluemanAuthAgentService config.user.name;

    systemd.services.bluetooth-rfkill-unblock = rfkillProjection.bootHelperService;

    systemd.services."bluetooth-rfkill-unblock@" = mkIf config.services.tlp.enable
      rfkillProjection.eventHelperService;

    services.udev.extraRules = rfkillProjection.udevRule;

    powerManagement.resumeCommands = rfkillProjection.resumeCommands;

    systemd.services.tlp-sleep.postStop = mkIf config.services.tlp.enable
      rfkillProjection.tlpSleepPostStop;

    # Keep the focused privacy/lifecycle and radio-boundary checks attached to
    # every Bluetooth generation without exposing their dependencies in PATH.
    system.extraDependencies = [
      bluemanAuthAgentTests
      bluetoothRfkillTests
      bluetoothPredeployVmTest
    ];
  }

  (mkIf (!config.services.tlp.enable) {
    systemd.services.systemd-rfkill = {
      overrideStrategy = "asDropin";
      serviceConfig.ExecStopPost = [ "${bluetoothRfkillFinalize}" ];
    };

    assertions = [{
      assertion =
        config.systemd.services.systemd-rfkill.serviceConfig.ExecStopPost
        == [ "${bluetoothRfkillFinalize}" ];
      message = "systemd-rfkill.service must have exactly one Bluetooth-only ExecStopPost finalizer";
    }];
  })
])
