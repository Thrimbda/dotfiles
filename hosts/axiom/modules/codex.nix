{ hey, config, pkgs, ... }:

let
  credential = config.age.secrets.codex-ntnl-key.path;
  codex = pkgs.writeShellScriptBin "codex" ''
    set -eu
    if [ ! -s ${credential} ]; then
      echo "Codex: missing NTNL credential at ${credential}" >&2
      exit 1
    fi
    export NTNL_API_KEY="$(cat ${credential})"
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

  home.file.".codex/config.toml".text = ''
    model = "gpt-6-astra"
    model_provider = "ntnl"

    [model_providers.ntnl]
    name = "NTNL"
    base_url = "https://openai.ntnl.io/v1"
    env_key = "NTNL_API_KEY"
    requires_openai_auth = false
    wire_api = "responses"
  '';
}
