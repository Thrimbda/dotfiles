{ lib }:

let
  inherit (lib) mkOption types;
in
rec {
  mkOpt  = type: default:
    mkOption { inherit type default; };

  mkOpt' = type: default: description:
    mkOption { inherit type default description; };

  mkBoolOpt = default: mkOption {
    inherit default;
    type = types.bool;
    example = true;
  };

  # Platform-aware environment variable setter
  # On Linux: uses environment.sessionVariables
  # On Darwin: uses environment.variables
  mkEnvVars = pkgs: vars:
    if pkgs.stdenv.isDarwin
    then { environment.variables = vars; }
    else { environment.sessionVariables = vars; };
}
