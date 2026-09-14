{ hey, config, pkgs, ... }:

let
  credential = config.age.secrets.codex-ntnl-openai-key.path;
  codex = pkgs.writeShellScriptBin "codex" ''
    set -eu
    if [ ! -s ${credential} ]; then
      echo "Codex: missing NTNL OpenAI credential at ${credential}" >&2
      exit 1
    fi
    export NTNL_OPENAI_API_KEY="$(cat ${credential})"
    exec ${hey.packages.codex}/bin/codex "$@"
  '';
in {
  # SSH App Server startup uses a noninteractive login shell. A system command
  # loads the credential without depending on interactive shell configuration.
  environment.systemPackages = [ codex ];

  age.secrets.codex-ntnl-openai-key = {
    owner = config.user.name;
    mode = "0400";
  };

  home.file.".codex/config.toml".text = ''
    model = "gpt-6-astra"
    model_provider = "ntnl-openai"

    [model_providers.ntnl-openai]
    name = "NTNL OpenAI"
    base_url = "https://openai.ntnl.io/v1"
    env_key = "NTNL_OPENAI_API_KEY"
    requires_openai_auth = true
    wire_api = "responses"
  '';
}
