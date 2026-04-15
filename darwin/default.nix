{ hey, lib, pkgs, config, ... }:

with lib;
with hey.lib;

let
  modulesCfg = config.modules or {};
  shellCfg = modulesCfg.shell or {};
  shellZsh = shellCfg.zsh or {};
  shellDirenv = shellCfg.direnv or {};
  shellGit = shellCfg.git or {};
  shellGnupg = shellCfg.gnupg or {};
  shellTmux = shellCfg.tmux or {};

  devCfg = modulesCfg.dev or {};
  devNode = devCfg.node or {};
  devDeno = devCfg.deno or {};
  devRust = devCfg.rust or {};
  devPython = devCfg.python or {};
  devJava = devCfg.java or {};

  editorsCfg = modulesCfg.editors or {};
  editorsDefault = editorsCfg.default or null;
  editorsVim = editorsCfg.vim or {};
  editorsEmacs = editorsCfg.emacs or {};

  heyWrapper = pkgs.writeShellScriptBin "hey" ''
    exec ${pkgs.janet}/bin/janet ${hey.binDir}/hey "$@"
  '';

  packages = with pkgs;
    unique (
      [ heyWrapper janet jpm jq git zsh ]
    );

in {
  imports = [
    ../modules/home.nix
    ../modules/xdg.nix
    ../modules/hey.nix
    ../modules/agenix.nix
    ../modules/services/cloudflared.nix

    # Shell
    ../modules/shell/zsh.nix
    ../modules/shell/git.nix
    ../modules/shell/gnupg.nix
    ../modules/shell/tmux.nix
    ../modules/shell/direnv.nix

    # Development
    ../modules/dev/default.nix
    ../modules/dev/node.nix
    ../modules/dev/deno.nix
    ../modules/dev/rust.nix
    ../modules/dev/python.nix
    ../modules/dev/java.nix
    ../modules/dev/playwright.nix

    # Editors & Theme
    ../modules/editors/default.nix
    ../modules/editors/vim.nix
    ../modules/editors/emacs.nix
    ../modules/themes/darwin.nix
  ];

  options = with lib.types; {
    modules = {};
    user = mkOpt attrs { name = ""; home = ""; };
  };

  config = {
    environment.variables = mkOrder 10 {
      DOTFILES_HOME = hey.dir;
      NIXPKGS_ALLOW_UNFREE = "1";
    };

    nix.settings = {
      warn-dirty = false;
      experimental-features = [ "nix-command" "flakes" ];
    };

    environment.shellAliases = mkIf (editorsDefault != null) {
      editor = editorsDefault;
    };

    environment.systemPackages = packages;
  };
}
