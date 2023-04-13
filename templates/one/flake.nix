{
  description = "A single-host NixOS config derived from hlissner/dotfiles";

  inputs = {
    # The name "super" is special to mkFlake, and will cause your flake to
    # inherit it, its nixpkgs (plus overlays), modules, and profiles.
    super.url = "github:hlissner/dotfiles";
  };

  outputs = inputs @ { ... }:
    dotfiles.lib.mkFlake inputs {
      # Required
      systems = [ "x86_64-linux" "aarch64-linux" ];
      hosts.foobar = import ./.;

      # Optional
      modules.default = import ./modules;
      profiles = mkProfiles [] ./profiles;
      overlays = mapModules ./overlays import;
      packages = mapModules ./packages import;
    };
};
