# vscode make it really easy to do anything.

{ config, options, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.editors.vscode;
in {
  options.modules.editors.vscode = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      (unstable.vscode-with-extensions.override {
        vscodeExtensions = with unstable.vscode-extensions; [
          ms-vscode.cpptools
        ];
      })
    ];
  };
}
