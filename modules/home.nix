# modules/home.nix -- the $HOME manager
#
# This is NOT a home-manager home.nix file. This NixOS module does two things:
#
# 1. Sets up home-manager to be used as NixOS module (exposing only a subset of
#    its API).
#
# 2. Enforce XDG compliance, whether programs want to or not. #
#
# I'm sure I'm reinventing wheels by not using more of home-manager's
# capabilities, but it's already an ordeal to maintain this config on top of
# nixpkgs and its rapidly-shifting idiosynchrosies (though it's still better
# than what I had before NixOS). home-manager is one black box too many for my
# liking.

{ hey, lib, config, options, pkgs, ... }:

with builtins;
with lib;
with hey.lib;
let cfg = config.home;
    userCfg = config.user or {};
    userName = userCfg.name or "";
    baseSessionVars = {
      # These are the defaults, and xdg.enable does set them, but due to load
      # order, they're not set before environment.variables are set, which
      # could cause race conditions.
      XDG_BIN_HOME    = cfg.binDir;
      XDG_CACHE_HOME  = cfg.cacheDir;
      XDG_CONFIG_HOME = cfg.configDir;
      XDG_DATA_HOME   = cfg.dataDir;
      XDG_STATE_HOME  = cfg.stateDir;

      # This is not in the XDG standard. It's my jail for stubborn programs,
      # like Firefox, Steam, and LMMS.
      XDG_FAKE_HOME = cfg.fakeDir;
      XDG_DESKTOP_DIR = cfg.fakeDir;
    };
in {
  imports =
    (optional (!pkgs.stdenv.isDarwin) hey.inputs.home-manager.nixosModules.home-manager)
    ++ (optional pkgs.stdenv.isDarwin hey.inputs.home-manager.darwinModules.home-manager);

  options.home = with types; {
    file       = mkOpt' attrs {} "Files to place directly in $HOME";
    configFile = mkOpt' attrs {} "Files to place in $XDG_CONFIG_HOME";
    dataFile   = mkOpt' attrs {} "Files to place in $XDG_DATA_HOME";
    fakeFile   = mkOpt' attrs {} "Files to place in $XDG_FAKE_HOME";
    packages   = mkOpt' (listOf package) [] "Packages to install into the user's home profile";

    dir        = mkOpt str "${config.user.home}";
    binDir     = mkOpt str "${cfg.dir}/.local/bin";
    cacheDir   = mkOpt str "${cfg.dir}/.cache";
    configDir  = mkOpt str "${cfg.dir}/.config";
    dataDir    = mkOpt str "${cfg.dir}/.local/share";
    stateDir   = mkOpt str "${cfg.dir}/.local/state";
    fakeDir    = mkOpt str "${cfg.dir}/.local/user";
  };

  config = mkIf (userName != "") (mkMerge [
    (optionalAttrs (!pkgs.stdenv.isDarwin) {
      environment.localBinInPath = true;
    })

    (if pkgs.stdenv.isDarwin then {
      environment.variables = mkOrder 10 baseSessionVars;
    } else {
      environment.sessionVariables = mkOrder 10 baseSessionVars;
    })

    # On Darwin, automatically map user.packages to home.packages
    # since nix-darwin doesn't support users.users.*.packages
    (mkIf (pkgs.stdenv.isDarwin && userCfg ? packages) {
      home.packages = userCfg.packages or [];
    })

    {
      home.file =
        mapAttrs' (k: v: nameValuePair "${config.home.fakeDir}/${k}" v)
          config.home.fakeFile;
    }

    {
      # Unify XDG-mapped files into our home.file option so downstream
      # consumers (home-manager alias) see them reliably on all platforms.
      home.file =
        (let
          mkHomeFiles = prefix: files:
            mapAttrs'
              (name: value: nameValuePair "${prefix}/${name}" value)
              (filterAttrs (_: v:
                isAttrs v && (v ? source || v ? text || v ? onChange || v ? executable || v ? recursive)
              ) files);
        in mkHomeFiles ".config" cfg.configFile
           // mkHomeFiles ".local/share" cfg.dataFile);
    }

    {
      home-manager = {
        useGlobalPkgs = false;
        useUserPackages = true;

        users.${config.user.name} =
          let
            mkHomeFiles = prefix: files:
              mapAttrs'
                (name: value: nameValuePair "${prefix}/${name}" value)
                files;
          in {
          home = {
            username = config.user.name;
            homeDirectory = config.user.home;
            stateVersion =
              let sysVersion = config.system.stateVersion;
              in if isString sysVersion then sysVersion else "24.11";
            # Delegate to our unified home.file (above) via aliasing.
            file = mkAliasDefinitions options.home.file;
            packages = mkAliasDefinitions options.home.packages;
          };
          xdg = {
            enable = true;
            cacheHome  = mkForce cfg.cacheDir;
            configHome = mkForce cfg.configDir;
            dataHome   = mkForce cfg.dataDir;
            stateHome  = mkForce cfg.stateDir;
          };
        } // (optionalAttrs pkgs.stdenv.isDarwin (
          let
            hmPkgsBase =
              import hey.inputs.home-manager.inputs.nixpkgs {
                inherit (pkgs) config;
                system = pkgs.stdenv.hostPlatform.system;
              };
            kdeconnectStub = hmPkgsBase.writeShellScriptBin "kdeconnect-kde" ''exit 0'';
            hmPkgs = hmPkgsBase // {
              plasma5Packages = (hmPkgsBase.plasma5Packages or {}) // {
                kdeconnect-kde = kdeconnectStub;
              };
            };
          in {
            services.kdeconnect.package = mkForce kdeconnectStub;
            _module.args.pkgs = mkForce hmPkgs;
          }
        ));
      };
    }
  ]);
}
