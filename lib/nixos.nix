# lib/flakes.nix --- syntax sugar for flakes
#
# This may look a lot like what flake-parts, flake-utils(-plus), and/or digga
# offer. I reinvent the wheel because (besides flake-utils), they are too
# volatile to depend on. They see subtle and unannounced changes, often. Since I
# rely on this flake as a basis for 100+ systems, VMs, and containers, some of
# whom are mission-critical, I'd rather have a less polished API that I fully
# control than a robust one that I cannot predict, for maximum mobility. It's
# also a more valuable learning experience.

{ self, lib, attrs, modules }:

with builtins;
with lib;
with attrs;
with modules;
rec {
  mkApp = program: {
    inherit program;
    type = "app";
  };

  # FIXME: Refactor me! (Use submodules?)
  mkFlake = {
    self
    , hey ? self
    , nixpkgs ? hey.inputs.nixpkgs
    , nixpkgs-unstable ? hey.inputs.nixpkgs-unstable or hey.inputs.nixpkgs-unstable or nixpkgs
    , nixpkgs-darwin ? hey.inputs.nixpkgs-darwin or nixpkgs
    , disko ? hey.inputs.disko
    , ...
  } @ inputs: {
    apps ? {}
    , checks ? {}
    , devShells ? {}
    , hosts ? {}
    , modules ? {}
    , overlays ? {}
    , packages ? {}
    , storage ? {}
    , systems
    , templates ? {}
    , ...
  } @ flake:
    let
      mkPkgs = system: pkgs: overlays: import pkgs {
        inherit system overlays;
        config.allowUnfree = true;
        # A number of packages depend on python 2.7, but nixpkgs errors out when
        # it is pulled, so...
        config.permittedInsecurePackages = [ "python-2.7.18.6" ];
      };

      overlaysList = attrValues overlays;

      # Processes external arguments that bin/hey will feed to this flake (using
      # a json payload in an envvar). The internal var is kept in lib to stop
      # 'nix flake check' from complaining more than it has to.
      args =
        let hargs = getEnv "HEYENV"; in
        if hargs == ""
        then abort "HEYENV envvar is missing"
        else fromJSON hargs;

      moduleSets =
        if modules ? nixos || modules ? darwin then modules else { nixos = modules; };

      mkModules = inputs':
        let
          nixos =
            filterMapAttrs
              (_: i: i ? nixosModules)
              (_: i: i.nixosModules)
              inputs';
          darwin =
            filterMapAttrs
              (_: i: i ? darwinModules)
              (_: i: i.darwinModules)
              inputs';
        in
          nixos // darwin // {
            inherit nixos darwin;
          };

      modulesFromInputs = mkModules inputs;
      nixosModules = modulesFromInputs.nixos;
      darwinModules = modulesFromInputs.darwin;
      modulesSelf = mkModules self.inputs;
      modulesHey = mkModules hey.inputs;

      bootstrapPkgs = import nixpkgs {};
      bootstrapModulesPath = "${nixpkgs}/nixos/modules";

      mkDotfiles = dir: hostPath:
        let
          resolvedDir =
            if dir != "" then dir
            else abort "No or invalid dir specified: ${dir}";
        in {
          dir = resolvedDir;
          binDir      = "${resolvedDir}/bin";
          libDir      = "${resolvedDir}/lib";
          configDir   = "${resolvedDir}/config";
          modulesDir  = "${resolvedDir}/modules";
          themesDir   = "${resolvedDir}/modules/themes";
        } // optionalAttrs (hostPath != null) {
          hostDir = hostPath;
        };

      baseSelf = self // mkDotfiles (toString self) null // {
        inherit args;
        modules = modulesSelf;
      };
      baseHey = hey // mkDotfiles args.path null // {
        inherit args;
        modules = modulesHey;
      };

      getSystemAttr = attrs: system: attrByPath [ system ] {} attrs;

      mkAugmented = base: modulesSet: dir: hostPath: system:
        base
        // mkDotfiles dir hostPath
        // {
          inherit args;
          modules = modulesSet;
        }
        // optionalAttrs (base ? packages) {
          packages = getSystemAttr base.packages system;
        }
        // optionalAttrs (base ? checks) {
          checks = getSystemAttr base.checks system;
        }
        // optionalAttrs (base ? devShells) {
          devShells = getSystemAttr base.devShells system;
        }
        // optionalAttrs (base ? devShell) {
          devShell = getSystemAttr base.devShell system;
        }
        // optionalAttrs (base ? apps) {
          apps = getSystemAttr base.apps system;
        };

      darwinInput =
        if inputs ? darwin then inputs.darwin
        else if hasAttr "nix-darwin" inputs then inputs."nix-darwin"
        else null;

      hostData =
        attrs.mapFilterAttrs'
          (hostName: { path, config }:
            let
              hostPath = toString path;
              hostBase = config {
                inherit args lib nixosModules darwinModules;
                hey = baseHey;
                pkgs = bootstrapPkgs;
                modulesPath = bootstrapModulesPath;
                config = {};
              };
              system =
                if hostBase ? system && isString hostBase.system then hostBase.system
                else trace "mkFlake: host ${hostName} missing system" null;
              osBase =
                if hostBase ? os then hostBase.os
                else if hasSuffix "-darwin" system || hasInfix "darwin" system then "darwin"
                else "nixos";
            in
              if system == null then
                nameValuePair "" null
              else
                let
                  overlaysForHost = overlaysList ++ [
                    (final: prev: {
                      unstable = mkPkgs system nixpkgs-unstable overlaysList;
                    })
                  ];
                  pkgsSource = if osBase == "darwin" then nixpkgs-darwin else nixpkgs;
                  pkgs = mkPkgs system pkgsSource overlaysForHost;
                  selfSpecial = mkAugmented baseSelf modulesSelf (toString self) hostPath system;
                  heySpecial = mkAugmented baseHey modulesHey args.path hostPath system;
                  host = config {
                    inherit args lib nixosModules darwinModules;
                    hey = heySpecial;
                    pkgs = pkgs;
                    modulesPath = bootstrapModulesPath;
                    config = {};
                  };
                  os =
                    if host ? os then host.os else osBase;
                  storage' = if host ? storage then host.storage else storage;
                in
                  nameValuePair hostName {
                    inherit hostName hostPath system pkgs os storage';
                    inherit host;
                    selfSpecial = selfSpecial;
                    heySpecial = heySpecial;
                  }
          )
          (_: v: v != null)
          hosts;

      nixosHosts = filterAttrs (_: v: v.os == "nixos") hostData;
      darwinHosts = filterAttrs (_: v: v.os == "darwin") hostData;

      hostMetadata =
        mapAttrs (_: v: {
          system = v.system;
          os = v.os;
          path = v.hostPath;
        }) hostData;

      nixosBaseModules =
        let defaults = attrValues (moduleSets.nixos or {});
        in if defaults == [] then [ ../. ] else defaults;

      darwinBaseModules =
        let defaults = attrValues (moduleSets.darwin or {});
        in if defaults == [] then [ ../darwin ] else defaults;

      nixosConfigurations =
        mapAttrs (hostName: hostInfo:
          let
            host = hostInfo.host;
            storageValue = hostInfo.storage';
          in
            nixpkgs.lib.nixosSystem {
              system = hostInfo.system;
              specialArgs = {
                self = hostInfo.selfSpecial;
                hey = hostInfo.heySpecial;
              };
              modules =
                [
                  disko.nixosModules.disko
                  (if isFunction storageValue
                   then (attrs: { disko.devices = storageValue attrs; })
                   else { disko.devices = storageValue; })
                  {
                    nixpkgs.pkgs = hostInfo.pkgs;
                    networking.hostName = mkDefault (args.host or hostName);
                  }
                ]
                ++ nixosBaseModules
                ++ (host.imports or [])
                ++ [ {
                  modules = host.modules or {};
                  # theme = host.theme or {};
                } ]
                ++ optional (host ? config) host.config
                ++ optional (host ? hardware) host.hardware;
            }
        ) nixosHosts;

      darwinConfigurations =
        if darwinHosts == {} then {}
        else
          let
            darwinLib =
              if darwinInput == null
              then abort "nix-darwin input is required when darwin hosts are defined."
              else darwinInput.lib;
          in
            mapAttrs (hostName: hostInfo:
              let host = hostInfo.host;
              in darwinLib.darwinSystem {
                system = hostInfo.system;
                enableNixpkgsReleaseCheck = false;
                specialArgs = {
                  self = hostInfo.selfSpecial;
                  hey = hostInfo.heySpecial;
                  pkgs = hostInfo.pkgs;
                };
                modules =
                  [
                    {
                      nixpkgs.hostPlatform = mkDefault hostInfo.system;
                      networking.hostName = mkDefault (args.host or hostName);
                    }
                  ]
                  ++ darwinBaseModules
                  ++ (host.imports or [])
                  ++ [ ({
                    modules = host.modules or {};
                  } // optionalAttrs (host ? user) {
                    user = host.user;
                  }) ]
                  ++ optional (host ? config) host.config;
              }
            ) darwinHosts;

      perSystem = map (system:
        let withPkgs = pkgs: packageAttrs:
              mapFilterAttrs
                (_: v: pkgs.callPackage v { self = self.packages.${system}; })
                (_: v: !(v ? meta.platforms) || (elem system v.meta.platforms))
                packageAttrs;
            pkgs = mkPkgs system nixpkgs overlaysList;
        in filterAttrs (_: v: v.${system} != {}) {
          apps.${system} = apps;
          checks.${system} = withPkgs pkgs checks;
          devShells.${system} = withPkgs pkgs devShells;
          packages.${system} = withPkgs pkgs packages;
        }) systems;
    in
      (filterAttrs (n: _: !elem n [
        "apps" "bundlers" "checks" "devices" "devShells" "hosts" "modules"
        "packages" "storage" "systems"
      ]) flake) // {
          inherit nixosConfigurations darwinConfigurations hostMetadata hostData;
          hostSystems = mapAttrs (_: v: v.system) hostData;
          nixosModules = moduleSets.nixos or {};
          darwinModules = moduleSets.darwin or {};

          # To parameterize this flake (more so for flakes derived from this
          # one) I rely on bin/hey (my nix{,os} CLI/wrapper) to emulate
          # --arg/--argstr options. 'dir' and 'host' are special though, and
          # communicated using hey's -f/--flake and --host options:
          #
          #   hey sync -f /etc/nixos#soba
          #   hey sync -f /etc/nixos --host soba
          #
          # The magic that allows this lives in mkFlake, but requires --impure
          # mode. Sorry hermetic purists!
          _heyArgs = args;
      } // (mergeAttrs' perSystem);
}
