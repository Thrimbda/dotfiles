{ config, ... }:

{
  # The CLI is installed under the user's home directory and updated in place
  # with `codex update`; Nix only makes its encrypted fallback credential
  # available to the user-owned launcher.
  age.secrets.codex-ntnl-key = {
    owner = config.user.name;
    mode = "0400";
  };

  # ~/.codex/config.toml is mutable user state. Provider/model selection and
  # settings written by Codex must survive subsequent system switches.
}
