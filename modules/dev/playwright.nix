{ hey, lib, config, options, pkgs, hostSystem ? null, ... }:

with lib;
with hey.lib;
let
  devCfg = config.modules.dev;
  cfg = devCfg.playwright;
  system = if hostSystem != null then hostSystem else pkgs.stdenv.hostPlatform.system;
  isDarwin = hasSuffix "-darwin" system;
  hasNixLd = builtins.hasAttr "programs" options && builtins.hasAttr "nix-ld" options.programs;
in {
  options.modules.dev.playwright = {
    enable = mkBoolOpt false;
    xdg.enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable (mkMerge [
    {
      user.packages = [ pkgs.playwright-test ];

      environment.shellAliases = {
        pw = "playwright";
      };
    }

    (mkIf isDarwin {
      home.packages = [ pkgs.playwright-test ];
    })

    (optionalAttrs hasNixLd {
      # Let browsers downloaded by npm/npx Playwright resolve their runtime
      # libraries through nix-ld on NixOS.
      programs.nix-ld.libraries = with pkgs; [
        alsa-lib
        at-spi2-atk
        atk
        cairo
        cups
        dbus
        expat
        glib
        gobject-introspection
        libgbm
        libxkbcommon
        nspr
        nss
        pango
        stdenv.cc.cc.lib
        systemd
        xorg.libX11
        xorg.libXcomposite
        xorg.libXdamage
        xorg.libXext
        xorg.libXfixes
        xorg.libXrandr
        xorg.libxcb
        libGL
        vulkan-loader
        pciutils
      ];
    })
  ]);
}
