# vscode make it really easy to do anything.

{ hey, config, options, lib, pkgs, ... }:

with lib;
with hey.lib;
let
  cfg = config.modules.editors.vscode;
  vscodePkg = pkgs.vscode-with-extensions.override {
    vscode = pkgs.vscode.fhs;
    vscodeExtensions = with pkgs.vscode-extensions; [
      ms-toolsai.datawrangler
      ms-toolsai.jupyter
      # vscode-with-extensions does not expand extensionPack entries for us.
      ms-toolsai.jupyter-keymap
      ms-toolsai.jupyter-renderers
      ms-toolsai.vscode-jupyter-cell-tags
      ms-toolsai.vscode-jupyter-slideshow
    ];
  };
in {
  options.modules.editors.vscode = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = [ vscodePkg ];
  };
}
