# flake.nix --- the heart of my dotfiles
#
# Author:  Henrik Lissner <contact@henrik.io>
# URL:     https://github.com/hlissner/dotfiles
# License: MIT
#
# Welcome to ground zero. Where the whole flake gets set up and all its modules
# are loaded.

{
  description = "A grossly incandescent nixos config.";

  inputs = 
    {
      # Core dependecies
      nixpkgs.url = "https://releases.nixos.org/nixos/26.05/nixos-26.05.7813.0dd31db7e6db/nixexprs.tar.xz";
      nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
      nixpkgs-vaultwarden.url = "nixpkgs/nixos-unstable";
      nixpkgs-darwin.url = "https://releases.nixos.org/nixpkgs/26.05-darwin/nixpkgs-darwin-26.05pre1012102.33da5f36e599/nixexprs.tar.xz";
      home-manager.url = "git+https://github.com/nix-community/home-manager?ref=release-26.05&rev=09ae1b85a6db412d841d60f924b23f881f0d0a38";
      home-manager.inputs.nixpkgs.follows = "nixpkgs";
      darwin.url = "git+https://github.com/nix-darwin/nix-darwin?ref=nix-darwin-26.05&rev=c3e90c89649b07d1a96e4b9dd6cd0d6e44b91a74";
      darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";
      agenix.url = "github:ryantm/agenix";
      agenix.inputs.nixpkgs.follows = "nixpkgs";
      disko.url = "github:nix-community/disko";
      disko.inputs.nixpkgs.follows = "nixpkgs";

      # Hyprland + core extensions
      # hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
      # hyprland.inputs.nixpkgs.follows = "nixpkgs";
      # Extras (imported directly by modules/hosts that need them)
      # hyprpicker.url = "github:hyprwm/hyprpicker";
      # hyprpicker.inputs.nixpkgs.follows = "nixpkgs-unstable";
      caelestia-shell.url = "github:caelestia-dots/shell";
      caelestia-shell.inputs.nixpkgs.follows = "nixpkgs-unstable";
      qtengine.url = "git+https://github.com/kossLAN/qtengine";
      qtengine.inputs.nixpkgs.follows = "nixpkgs-unstable";
      blender-bin.url = "github:edolstra/nix-warez?dir=blender";
      blender-bin.inputs.nixpkgs.follows = "nixpkgs-unstable";
      emacs-overlay.url = "github:nix-community/emacs-overlay";
      emacs-overlay.inputs.nixpkgs.follows = "nixpkgs";
      nixos-hardware.url = "github:nixos/nixos-hardware";

      # nix-ld
      nix-ld.url = "github:Mic92/nix-ld";
      # this line assume that you also have nixpkgs as an input
      nix-ld.inputs.nixpkgs.follows = "nixpkgs";

      nixos-wsl.url = "github:nix-community/NixOS-WSL/main";

      # Zen is not exposed by the pinned nixpkgs/unstable set, so keep the
      # browser source narrow rather than promoting another browser baseline.
      zen-browser.url = "github:0xc000022070/zen-browser-flake";
      zen-browser.inputs.nixpkgs.follows = "nixpkgs-unstable";

      sidra.url = "github:wimpysworld/sidra";
      sidra.inputs.nixpkgs.follows = "nixpkgs-unstable";

      dwproton.url = "github:imaviso/dwproton-flake";
      dwproton.inputs.nixpkgs.follows = "nixpkgs";
    };

  outputs = inputs @ { self, nixpkgs, nixpkgs-unstable, nixos-hardware, ... }:
    let
      detectSystem =
        let
          inherit (nixpkgs.lib.strings) hasInfix toLower;
          envSystem = builtins.getEnv "NIX_SYSTEM";
          envHost = toLower (builtins.getEnv "HOSTTYPE");
          envOs = toLower (builtins.getEnv "OSTYPE");
          isDarwin = hasInfix "darwin" envOs;
          isArm = hasInfix "arm" envHost || hasInfix "aarch64" envHost;
        in
          if builtins ? currentSystem then builtins.currentSystem
          else if envSystem != "" then envSystem
          else if isDarwin then (if isArm then "aarch64-darwin" else "x86_64-darwin")
          else if isArm then "aarch64-linux"
          else "x86_64-linux";

      args = {
        inherit self;
        inherit (nixpkgs) lib;
        pkgs = import nixpkgs { system = detectSystem; };
      };
      lib = import ./lib args;
    in
      with builtins; with lib; mkFlake inputs {
        systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
        inherit lib;

        hosts = mapHosts ./hosts;
        modules = {
          nixos.default = import ./.;
          darwin.default = import ./darwin;
        };

        apps.install = mkApp ./install.zsh;
        devShells.default = import ./shell.nix;
        checks = mapModules ./test import;
        overlays = mapModules ./overlays import;
        packages = mapModules ./packages import;
        # templates = import ./templates args;
      };
}
