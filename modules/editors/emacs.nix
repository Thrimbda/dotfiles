# Emacs is my main driver. I'm the author of Doom Emacs
# https://github.com/doomemacs. This module sets it up to meet my particular
# Doomy needs.

{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
let
  cfg = config.modules.editors.emacs;
  desktop = config.modules.desktop or {};
  desktopType = desktop.type or null;
  isDarwin = pkgs.stdenv.isDarwin;
  doomCfg = if cfg ? doom then cfg.doom else {};
  doomEnabled = attrByPath [ "enable" ] false doomCfg;
  doomRepo = attrByPath [ "repoUrl" ] "https://github.com/doomemacs/doomemacs" doomCfg;
  doomConfigRepo = attrByPath [ "configRepoUrl" ] "https://github.com/hlissner/.doom.d" doomCfg;
  baseEmacsPackage =
    let
      waylandCandidate = pkgs.emacs-git-pgtk or pkgs.emacs-pgtk or pkgs.emacs;
      defaultCandidate = pkgs.emacs-git or pkgs.emacs;
    in if desktopType == "wayland" then waylandCandidate else defaultCandidate;
  emacs = pkgs.emacsPackagesFor baseEmacsPackage;
  emacsWithExtras = emacs.emacsWithPackages (epkgs: with epkgs; [
    treesit-grammars.with-all-grammars
    vterm
    mu4e
  ]);
  emacsPackagesBase = with pkgs; [
    (mkLauncherEntry "Emacs (Debug Mode)" {
      description = "Start Emacs in debug mode";
      icon = "emacs";
      exec = "${emacsWithExtras}/bin/emacs --debug-init";
    })

    ## Emacs itself
    binutils            # native-comp needs 'as', provided by this
    emacsWithExtras               # HEAD + native-comp

    ## Doom dependencies
    git
    ripgrep
    gnutls              # for TLS connectivity

    ## Optional dependencies
    fd                  # faster projectile indexing
    imagemagick         # for image-dired
    zstd                # for undo-fu-session/undo-tree compression

    librime

    ## Module dependencies
    # :email mu4e
    mu
    isync
    # :checkers spell
    (aspellWithDicts (ds: with ds; [ en en-computers en-science ]))
    # :tools editorconfig
    editorconfig-core-c # per-project style config
    # :tools lookup & :lang org +roam
    sqlite
    # :lang cc
    clang-tools
    # :lang latex & :lang org (latex previews)
    texlive.combined.scheme-medium
    # :lang beancount
    beancount
    fava
    # :lang nix
    age
  ];
  emacsPackagesList =
    emacsPackagesBase
    ++ optional (config.programs.gnupg.agent.enable) pkgs.pinentry-emacs;
in {
  options.modules.editors.emacs = {
    enable = mkBoolOpt false;
    # doom = rec {
    #   enable = mkBoolOpt false;
    #   forgeUrl = mkOpt types.str "https://github.com";
    #   repoUrl = mkOpt types.str "${forgeUrl}/doomemacs/doomemacs";
    #   configRepoUrl = mkOpt types.str "${forgeUrl}/hlissner/.doom.d";
    # };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkMerge [
      {
      nixpkgs.overlays = [
        hey.inputs.emacs-overlay.overlays.default
      ];

      user.packages = emacsPackagesList;

      modules.shell.zsh.rcFiles = [ "${hey.configDir}/emacs/aliases.zsh" ];
      modules.shell.zsh.envInit = mkBefore ''
        # Prepend Doom's bin wrapper directory without clobbering PATH
        path=("$XDG_CONFIG_HOME/emacs/bin" "''${path[@]}")
        typeset -U path PATH
      '';
      }

      (mkIf isDarwin {
        home.packages = emacsPackagesList;

        system.activationScripts.linkEmacsApp.text = ''
          src='${emacsWithExtras}/Applications/Emacs.app'
          dest='/Applications/Emacs.app'
          mkdir -p /Applications
          if [ -e "$dest" ] || [ -L "$dest" ]; then
            rm -rf "$dest"
          fi
          ln -sfn "$src" "$dest"
        '';
      })
    ])

    (if isDarwin then {} else {
      fonts.packages = [
        (pkgs.nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
      ];
      system.userActivationScripts = mkIf doomEnabled {
        installDoomEmacs = ''
          if [ ! -d "$XDG_CONFIG_HOME/emacs" ]; then
            git clone --depth=1 --single-branch "${doomRepo}" "$XDG_CONFIG_HOME/emacs"
            git clone "${doomConfigRepo}" "$XDG_CONFIG_HOME/doom"
          fi
        '';
      };
    })
  ]);
}
