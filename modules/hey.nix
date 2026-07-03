# modules/hey.nix -- powering my binscripts
#
# ZSH and Janet are the powerhouses of my dotfiles. This module configures both
# for my scripting needs (particularly by bin/hey).

{ hey, lib, options, config, pkgs, hostSystem ? null, ... }:

with builtins;
with lib;
with hey.lib;
let cfg = config.hey;
    system = if hostSystem != null then hostSystem else pkgs.stdenv.hostPlatform.system;
    isDarwin = hasSuffix "-darwin" system;

    janet = pkgs.janet;
    jpmWrapped = mkWrapper pkgs.jpm ''
      wrapProgram $out/bin/jpm --add-flags '--tree="$JANET_TREE" --binpath="$XDG_BIN_HOME" --headerpath=${janet}/include --libpath=${janet}/lib'
    '';
    jpmPkg = if isDarwin then pkgs.jpm else jpmWrapped;
    janetTreeDir = "${config.home.dataDir}/janet/jpm_tree";
    xdgFallbackExports = optionalString (!isDarwin) ''
      export XDG_CONFIG_HOME="''${XDG_CONFIG_HOME:-$HOME/.config}"
      export XDG_CACHE_HOME="''${XDG_CACHE_HOME:-$HOME/.cache}"
      export XDG_DATA_HOME="''${XDG_DATA_HOME:-$HOME/.local/share}"
      export XDG_STATE_HOME="''${XDG_STATE_HOME:-$HOME/.local/state}"
      export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
    '';
    heyWrapper = pkgs.writeShellScriptBin "hey" ''
      ${xdgFallbackExports}
      export JANET_PATH=${hey.libDir}:${janetTreeDir}/lib
      export JANET_TREE=${janetTreeDir}
      exec ${janet}/bin/janet ${hey.binDir}/hey "$@"
    '';
in {
  options = with types; {
    hey = {
      info = mkOpt (attrsOf attrs) {};
      hooks = mkOpt (attrsOf (attrsOf lines)) {};
    };
  };

  config = mkMerge [
    {
    # So systemd services in downstream modules/profiles can call hey without
    # dealing with PATH shenanigans.
    _module.args.heyBin = "${heyWrapper}/bin/hey";

    environment.systemPackages =
      [ heyWrapper janet jpmPkg pkgs.jq pkgs.git pkgs.zsh ]
      ++ optional (!isDarwin) pkgs.gcc
      ++ optional (!isDarwin) pkgs.cached-nix-shell
      ++ optional (!isDarwin) pkgs.bind
      ++ optional (!isDarwin) pkgs.dash
      ++ optional (!isDarwin) pkgs.wget
      ++ optional (!isDarwin) pkgs.nix-prefetch-git;

    environment.variables =
      {
        JANET_PATH = hey.libDir;
        JANET_TREE = hey.libDir;
      }
      // (optionalAttrs (!isDarwin) {
        JANET_PATH = mkForce "${janetTreeDir}/lib";
        JANET_TREE = mkForce janetTreeDir;
      });
  }

    (optionalAttrs (!isDarwin) {
      # Compile bin/hey to trivialize janet startup time
      # TODO: Include gcc for 'jpm deps'
      system.userActivationScripts.initHey = ''
        ${xdgFallbackExports}

        ${pkgs.coreutils}/bin/install -d -m 0755 "${janetTreeDir}"

        janet_version="$(${janet}/bin/janet --version)"
        janet_version_file="${janetTreeDir}/.nix-managed-janet-version"
        project_hash="$(${pkgs.coreutils}/bin/sha256sum '${hey.dir}/project.janet' | ${pkgs.coreutils}/bin/cut -d ' ' -f1)"
        project_hash_file="${janetTreeDir}/.nix-managed-project-sha256"

        hey_runtime_usable() {
          DOTFILES_HOME='${hey.dir}' \
          JANET_PATH="${hey.libDir}:${janetTreeDir}/lib" \
          JANET_TREE="${janetTreeDir}" \
          ${janet}/bin/janet ${hey.binDir}/hey path home >/dev/null 2>&1
        }

        rebuild_hey=false
        if [ ! -f "$janet_version_file" ] || [ "$(${pkgs.coreutils}/bin/cat "$janet_version_file")" != "$janet_version" ]; then
          rebuild_hey=true
        elif [ ! -f "$project_hash_file" ] || [ "$(${pkgs.coreutils}/bin/cat "$project_hash_file")" != "$project_hash" ]; then
          rebuild_hey=true
        elif ! hey_runtime_usable; then
          rebuild_hey=true
        fi

        ${pkgs.coreutils}/bin/install -d -m 0755 "$XDG_DATA_HOME/hey"
        ${pkgs.zsh}/bin/zsh -c 'echo $PATH' >"$XDG_DATA_HOME/hey/path"

        if [ "$rebuild_hey" = true ]; then
          stage_tree="$(${pkgs.coreutils}/bin/mktemp -d "${janetTreeDir}.staging.XXXXXX")"
          cleanup_stage() {
            ${pkgs.coreutils}/bin/rm -rf "''${stage_tree:-}"
          }
          trap cleanup_stage EXIT

          if (
            export JANET_PATH="$stage_tree/lib"
            export JANET_TREE="$stage_tree"
            export XDG_BIN_HOME="$stage_tree/bin"
            export PATH="${jpmPkg}/bin:${pkgs.git}/bin:${pkgs.gcc}/bin:${pkgs.coreutils}/bin:$PATH"
            ${pkgs.coreutils}/bin/install -d -m 0755 "$JANET_TREE" "$JANET_PATH" "$JANET_PATH/.cache" "$XDG_BIN_HOME"
            cd '${hey.dir}'
            ${jpmPkg}/bin/jpm deps
            ${jpmPkg}/bin/jpm run deploy
            DOTFILES_HOME='${hey.dir}' ${janet}/bin/janet ${hey.binDir}/hey path home >/dev/null
          ); then
            ${pkgs.coreutils}/bin/rm -rf "${janetTreeDir}/build" "${janetTreeDir}/lib" "${janetTreeDir}/man"
            ${pkgs.coreutils}/bin/install -d -m 0755 "${janetTreeDir}/bin"
            [ -e "$stage_tree/build" ] && ${pkgs.coreutils}/bin/mv "$stage_tree/build" "${janetTreeDir}/build"
            [ -e "$stage_tree/lib" ] && ${pkgs.coreutils}/bin/mv "$stage_tree/lib" "${janetTreeDir}/lib"
            [ -e "$stage_tree/man" ] && ${pkgs.coreutils}/bin/mv "$stage_tree/man" "${janetTreeDir}/man"
            if [ -e "$stage_tree/bin/hey" ]; then
              ${pkgs.coreutils}/bin/rm -f "${janetTreeDir}/bin/hey"
              ${pkgs.coreutils}/bin/mv "$stage_tree/bin/hey" "${janetTreeDir}/bin/hey"
            fi
            ${pkgs.coreutils}/bin/printf '%s\n' "$janet_version" > "$janet_version_file"
            ${pkgs.coreutils}/bin/printf '%s\n' "$project_hash" > "$project_hash_file"
          elif hey_runtime_usable; then
            printf 'initHey: keeping existing JPM tree because staged rebuild failed\n' >&2
          else
            printf 'initHey: staged JPM rebuild failed and no usable existing hey runtime remains\n' >&2
            exit 1
          fi

          trap - EXIT
          cleanup_stage
        fi
      '';

      systemd.user.tmpfiles.rules = [
        "d %h/.local/share/janet/jpm_tree 755 - - - -"
      ];

      environment.sessionVariables = {
        JANET_PATH = "${janetTreeDir}/lib";
        JANET_TREE = janetTreeDir;
      };
    })

    (optionalAttrs isDarwin {
      environment.variables = {
        JANET_PATH = hey.libDir;
        JANET_TREE = hey.libDir;
      };
    })

    {
      programs.zsh.shellInit = mkBefore ''
        export DOTFILES_HOME="${hey.dir}"
        export fpath=( "${hey.libDir}/zsh" "''${fpath[@]}" )
        autoload -Uz "''${fpath[1]}"/hey.*(.:t)
      '';

      home.dataFile = {
        # This file is intended as a reference for shell scripts to peek into to
        # do cheap feature-detection (using `hey vars ...`)
        "hey/info.json".text = toJSON cfg.info;
      } //
      # FIXME: Refactor me?
      (listToAttrs
        (flatten
          (mapAttrsToList
            (hook: hooks: mapAttrsToList
              (n: v: nameValuePair
                (let filename =
                       if (match "^[0-9]{2}-.+" n) == null
                       then "50-${n}"
                       else n;
                 in "hey/hooks.d/${hook}.d/${filename}") {
                   text = ''
                     #!/usr/bin/env zsh
                     ${v}
                   '';
                   executable = true;
                 }) hooks)
            config.hey.hooks)));
    }
  ];
}
