{ hey, config, pkgs, ... }:

let
  credential = config.age.secrets.codex-ntnl-key.path;
  codex = pkgs.writeShellScriptBin "codex" ''
    set -eu
    if [ -z "''${NTNL_API_KEY:-}" ] && [ -r ${credential} ]; then
      export NTNL_API_KEY="$(cat ${credential})"
    fi
    exec ${hey.packages.codex}/bin/codex "$@"
  '';
in {
  # SSH App Server startup uses a noninteractive login shell. A system command
  # loads the credential without depending on interactive shell configuration.
  environment.systemPackages = [ codex ];

  age.secrets.codex-ntnl-key = {
    owner = config.user.name;
    mode = "0400";
  };

  # ~/.codex/config.toml is mutable user state. Provider/model selection and
  # settings written by Codex must survive subsequent system switches.
}
