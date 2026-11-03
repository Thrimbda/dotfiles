{ pkgs, ... }:

let
  lutris = pkgs.unstable.lutris.override {
    # Lutris 0.5.22 probes /usr/bin/vulkaninfo; expose it inside its FHS env.
    extraPkgs = p: [ p.vulkan-tools ];
    lutris-unwrapped = pkgs.unstable.lutris-unwrapped.overrideAttrs (old: {
      # The installer otherwise rewrites the umu sentinel to ge-proton-x86_64
      # and tries to download it from Lutris's ordinary Wine runner catalog.
      postPatch = (old.postPatch or "") + ''
        substituteInPlace lutris/runners/wine.py \
          --replace-fail 'version = normalize_version_architecture(version)' \
            'version = version if version == GE_PROTON_LATEST else normalize_version_architecture(version)' \
          --replace-fail 'installer_runner_config["version"] = normalize_version_architecture(version)' \
            'installer_runner_config["version"] = version if version == GE_PROTON_LATEST else normalize_version_architecture(version)'
      '';
    });
  };
  installer = ./battlenet-cn.yml;
  launcher = pkgs.writeShellApplication {
    name = "battlenet";
    runtimeInputs = [ lutris pkgs.unstable.umu-launcher ];
    text = ''
      if [[ "''${1:-}" == "--install" ]]; then
        shift
        exec lutris --install ${installer} "$@"
      fi
      # Lutris owns its mutable library and prefix, just as Steam owns its
      # writable client. Neither Battle.net nor its updater lives in the store.
      exec lutris lutris:rungame/battlenet-cn "$@"
    '';
  };
  desktop = pkgs.makeDesktopItem {
    name = "battlenet-cn";
    desktopName = "Battle.net 国服战网";
    genericName = "Blizzard game launcher";
    comment = "国服战网与魔兽世界 / Battle.net China via GE-Proton";
    exec = "${launcher}/bin/battlenet";
    icon = "net.lutris.Lutris";
    categories = [ "Game" ];
    keywords = [ "Battle.net" "Battlenet" "Blizzard" "战网" "魔兽世界" "WoW" ];
    actions.Install = {
      name = "安装国服战网";
      exec = "${launcher}/bin/battlenet --install";
    };
  };
in {
  environment.systemPackages = [ lutris pkgs.unstable.umu-launcher launcher desktop ];

  # A portal activated before Hyprland's 05-session environment import keeps
  # an empty DISPLAY and cannot open Battle.net's browser login in Zen.
  hey.hooks.startup."06-portal-environment" = ''
    hey.do systemctl --user try-restart xdg-desktop-portal.service
  '';

  # A recipe, not a managed prefix: installation and all subsequent Battle.net
  # and game updates happen as the desktop user without a NixOS rebuild.
  environment.etc."lutris/battlenet-cn.yml".source = installer;
}
