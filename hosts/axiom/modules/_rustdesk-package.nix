{ pkgs }:

let
  version = "1.4.9";
  sourceHash = "sha256-AnwdIO4TveC48uMioBCvH60xun24ckK420ONSEB9lQI=";
  cargoHash = "sha256-HPvvsTcjSErGfdNwsHgWhs930Fe0hmK1g5J/ngtlkKM=";
  source = pkgs.unstable.fetchFromGitHub {
    owner = "rustdesk";
    repo = "rustdesk";
    rev = "6c578292e8ebbbec708b76986ba8c4bc7c509747";
    fetchSubmodules = true;
    hash = sourceHash;
  };
  cargoDeps = pkgs.unstable.rustPlatform.fetchCargoVendor {
    name = "rustdesk-${version}";
    src = source;
    hash = cargoHash;
  };
  package = pkgs.unstable.rustdesk.overrideAttrs (_finalAttrs: _previousAttrs: {
    inherit version;
    src = source;
    inherit cargoHash cargoDeps;
  });
in {
  inherit version sourceHash cargoHash source cargoDeps package;
}
