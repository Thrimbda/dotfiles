# modules/browser/librewolf.nix --- https://librewolf.net/
#
# Oh Librewolf, gateway to the interwebs, devourer of ram. Give onto me your
# infinite knowledge and shelter me from ads, but bless my $HOME with
# directories nobody needs and live long enough to turn into Chrome.

{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop.browsers.librewolf;
in {
  options.modules.desktop.browsers.librewolf = with types; {
    enable = mkBoolOpt false;
    profileName = mkOpt str config.user.name;

    settings = mkOpt' (attrsOf (oneOf [ bool int str ])) {} ''
      Librewolf preferences to set in <filename>user.js</filename>
    '';
    extraConfig = mkOpt' lines "" ''
      Extra lines to add to <filename>user.js</filename>
    '';

    userChrome  = mkOpt' lines "" "CSS Styles for Librewolf's interface";
    userContent = mkOpt' lines "" "Global CSS Styles for websites";

    # TODO
    # profiles = attrsOf (submodule ({ config, ... }: {
    #   options = {
    #     name = mkOpt str config._module.args.name;
    #     default = mkOpt bool false;
    #     settings = mkOpt' (attrsOf (oneOf [ bool int str ])) {} ''
    #       Librewolf preferences to set in <filename>user.js</filename>
    #     '';
    #     extraConfig = mkOpt' lines "" ''
    #       Extra lines to add to <filename>user.js</filename>
    #     '';
    #     userChrome  = mkOpt' lines "" "CSS Styles for Librewolf's interface";
    #     userContent = mkOpt' lines "" "Global CSS Styles for websites";
    #   };
    # }));
  };

  config = mkIf cfg.enable {
    programs.firefox = {
      enable = true;
      package = pkgs.unstable.librewolf;
      # nativeMessagingHosts.packages = with pkgs; [
      #   tridactyl-native
      # ];
      policies = {
        DontCheckDefaultBrowser = true;
        DisablePocket = true;
        DisableAppUpdate = true;
      };
    };

    user.packages = with pkgs; with hey.lib.pkgs; [
      # Obey XDG, damn it!
      (writeShellScriptBin "librewolf" ''
        export HOME="$XDG_FAKE_HOME"
        exec "${config.programs.firefox.package}/bin/librewolf" "$@"
      '')
    ];

    modules.desktop.browsers.librewolf.settings = {
      # Allow svgs to take on theme colors
      "svg.context-properties.content.enabled" = true;
      # Pressing TAB from address bar shouldn't cycle through buttons before
      # switching focus back to the webppage. Most of those buttons have
      # dedicated shortcuts, so I don't need this level of tabstop granularity.
      "browser.toolbars.keyboard_navigation" = false;

      # Seriously. Stop popping up on every damn page. If I want it translated,
      # I know where to find gtranslate/deepl/whatever!
      "browser.translations.automaticallyPopup" = false;
      # Enable ETP for decent security (makes firefox containers and many
      # common security/privacy add-ons redundant).
      "browser.contentblocking.category" = "strict";
      "privacy.donottrackheader.enabled" = true;
      "privacy.donottrackheader.value" = 1;
      "privacy.purge_trackers.enabled" = true;
      # Your customized toolbar settings are stored in
      # 'browser.uiCustomization.state'. This tells firefox to sync it between
      # machines. WARNING: This may not work across OSes. Since I use NixOS on
      # all the machines I use Firefox on, this is no concern to me.
      "services.sync.prefs.sync.browser.uiCustomization.state" = true;
      # Enable userContent.css and userChrome.css for our theme modules
      "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
      # Stop creating ~/Downloads!
      "browser.download.dir" = "${config.user.home}/downloads";
      # Don't use the built-in password manager. A nixos user is more likely
      # using an external one (you are using one, right?).
      "signon.rememberSignons" = false;
      # Do not check if Firefox is the default browser
      "browser.shell.checkDefaultBrowser" = false;
      # Disable the "new tab page" feature and show a blank tab instead
      # https://wiki.mozilla.org/Privacy/Reviews/New_Tab
      # https://support.mozilla.org/en-US/kb/new-tab-page-show-hide-and-customize-top-sites#w_how-do-i-turn-the-new-tab-page-off
      "browser.newtabpage.enabled" = false;
      "browser.newtab.url" = "about:blank";
      # Disable Activity Stream
      # https://wiki.mozilla.org/Firefox/Activity_Stream
      "browser.newtabpage.activity-stream.enabled" = false;
      "browser.newtabpage.activity-stream.telemetry" = false;
      # Disable new tab tile ads & preload
      # http://www.thewindowsclub.com/disable-remove-ad-tiles-from-firefox
      # http://forums.mozillazine.org/viewtopic.php?p=13876331#p13876331
      # https://wiki.mozilla.org/Tiles/Technical_Documentation#Ping
      # https://gecko.readthedocs.org/en/latest/browser/browser/DirectoryLinksProvider.html#browser-newtabpage-directory-source
      # https://gecko.readthedocs.org/en/latest/browser/browser/DirectoryLinksProvider.html#browser-newtabpage-directory-ping
      "browser.newtabpage.enhanced" = false;
      "browser.newtabpage.introShown" = true;
      "browser.newtab.preload" = false;
      "browser.newtabpage.directory.ping" = "";
      "browser.newtabpage.directory.source" = "data:text/plain,{}";
      # Reduce search engine noise in the urlbar's completion window. The
      # shortcuts and suggestions will still work, but Firefox won't clutter
      # its UI with reminders that they exist.
      "browser.urlbar.suggest.searches" = false;
      "browser.urlbar.shortcuts.bookmarks" = false;
      "browser.urlbar.shortcuts.history" = false;
      "browser.urlbar.shortcuts.tabs" = false;
      "browser.urlbar.showSearchSuggestionsFirst" = false;
      "browser.urlbar.speculativeConnect.enabled" = false;
      # Since FF 113, you must press TAB twice to cycle through urlbar
      # suggestions. This disables that.
      "browser.urlbar.resultMenu.keyboardAccessible" = false;
      # https://bugzilla.mozilla.org/1642623
      "browser.urlbar.dnsResolveSingleWordsAfterSearch" = 0;
      # https://blog.mozilla.org/data/2021/09/15/data-and-firefox-suggest/
      "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
      "browser.urlbar.suggest.quicksuggest.sponsored" = false;
      # Show whole URL in address bar
      "browser.urlbar.trimURLs" = false;
      # Disable some not so useful functionality.
      "browser.disableResetPrompt" = true;       # "Looks like you haven't started Firefox in a while."
      "browser.onboarding.enabled" = false;      # "New to Firefox? Let's get started!" tour
      "browser.aboutConfig.showWarning" = false; # Warning when opening about:config
      "media.videocontrols.picture-in-picture.video-toggle.enabled" = false;
      "extensions.pocket.enabled" = false;
      "extensions.unifiedExtensions.enabled" = false;
      "extensions.shield-recipe-client.enabled" = false;
      "reader.parse-on-load.enabled" = false;  # "reader view"

      # Security-oriented defaults
      "security.family_safety.mode" = 0;
      # https://blog.mozilla.org/security/2016/10/18/phasing-out-sha-1-on-the-public-web/
      "security.pki.sha1_enforcement_level" = 1;
      # https://github.com/tlswg/tls13-spec/issues/1001
      "security.tls.enable_0rtt_data" = false;
      # Use Mozilla geolocation service instead of Google if given permission
      "geo.provider.network.url" = "https://location.services.mozilla.com/v1/geolocate?key=%MOZILLA_API_KEY%";
      "geo.provider.use_gpsd" = false;
      # https://support.mozilla.org/en-US/kb/extension-recommendations
      "browser.newtabpage.activity-stream.asrouter.userprefs.cfr" = false;
      "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
      "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
      "extensions.htmlaboutaddons.recommendations.enabled" = false;
      "extensions.htmlaboutaddons.discover.enabled" = false;
      "extensions.getAddons.showPane" = false;  # uses Google Analytics
      "browser.discovery.enabled" = false;
      # Reduce File IO / SSD abuse
      # Otherwise, Firefox bombards the HD with writes. Not so nice for SSDs.
      # This forces it to write every 30 minutes, rather than 15 seconds.
      "browser.sessionstore.interval" = "1800000";
      # Disable battery API
      # https://developer.mozilla.org/en-US/docs/Web/API/BatteryManager
      # https://bugzilla.mozilla.org/show_bug.cgi?id=1313580
      "dom.battery.enabled" = false;
      # Disable "beacon" asynchronous HTTP transfers (used for analytics)
      # https://developer.mozilla.org/en-US/docs/Web/API/navigator.sendBeacon
      "beacon.enabled" = false;
      # Disable pinging URIs specified in HTML <a> ping= attributes
      # http://kb.mozillazine.org/Browser.send_pings
      "browser.send_pings" = false;
      # Disable gamepad API to prevent USB device enumeration
      # https://www.w3.org/TR/gamepad/
      # https://trac.torproject.org/projects/tor/ticket/13023
      "dom.gamepad.enabled" = false;
      # Don't try to guess domain names when entering an invalid domain name in URL bar
      # http://www-archive.mozilla.org/docs/end-user/domain-guessing.html
      "browser.fixup.alternate.enabled" = false;
      # Disable telemetry
      # https://wiki.mozilla.org/Platform/Features/Telemetry
      # https://wiki.mozilla.org/Privacy/Reviews/Telemetry
      # https://wiki.mozilla.org/Telemetry
      # https://www.mozilla.org/en-US/legal/privacy/firefox.html#telemetry
      # https://support.mozilla.org/t5/Firefox-crashes/Mozilla-Crash-Reporter/ta-p/1715
      # https://wiki.mozilla.org/Security/Reviews/Firefox6/ReviewNotes/telemetry
      # https://gecko.readthedocs.io/en/latest/browser/experiments/experiments/manifest.html
      # https://wiki.mozilla.org/Telemetry/Experiments
      # https://support.mozilla.org/en-US/questions/1197144
      # https://firefox-source-docs.mozilla.org/toolkit/components/telemetry/telemetry/internals/preferences.html#id1
      "toolkit.telemetry.unified" = false;
      "toolkit.telemetry.enabled" = false;
      "toolkit.telemetry.server" = "data:,";
      "toolkit.telemetry.archive.enabled" = false;
      "toolkit.telemetry.coverage.opt-out" = true;
      "toolkit.coverage.opt-out" = true;
      "toolkit.coverage.endpoint.base" = "";
      "experiments.supported" = false;
      "experiments.enabled" = false;
      "experiments.manifest.uri" = "";
      "browser.ping-centre.telemetry" = false;
      # https://mozilla.github.io/normandy/
      "app.normandy.enabled" = false;
      "app.normandy.api_url" = "";
      "app.shield.optoutstudies.enabled" = false;
      # Disable health reports (basically more telemetry)
      # https://support.mozilla.org/en-US/kb/firefox-health-report-understand-your-browser-perf
      # https://gecko.readthedocs.org/en/latest/toolkit/components/telemetry/telemetry/preferences.html
      "datareporting.healthreport.uploadEnabled" = false;
      "datareporting.healthreport.service.enabled" = false;
      "datareporting.policy.dataSubmissionEnabled" = false;

      # Disable crash reports
      "breakpad.reportURL" = "";
      "browser.tabs.crashReporting.sendReport" = false;
      "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;  # don't submit backlogged reports

      # Disable Form autofill
      # https://wiki.mozilla.org/Firefox/Features/Form_Autofill
      "browser.formfill.enable" = false;
      "extensions.formautofill.addresses.enabled" = false;
      "extensions.formautofill.available" = "off";
      "extensions.formautofill.creditCards.available" = false;
      "extensions.formautofill.creditCards.enabled" = false;
      "extensions.formautofill.heuristics.enabled" = false;
    };

    home =
      let localDir = "${config.home.fakeDir}/.librewolf";
      in {
        # configFile."tridactyl" = {
        #   source = "${hey.configDir}/tridactyl";
        #   recursive = true;
        # };

        # programs.firefox.nativeMessagingHosts.tridactyl doesn't seem to be
        # enough, so install the native messenger manually.
        # fakeFile.".mozilla/native-messaging-hosts/tridactyl.json".source =
        #   let version = "0.3.6";
        #       manifestURL = "https://raw.githubusercontent.com/tridactyl/native_messenger/${version}/tridactyl.json";
        #       manifest = pkgs.runCommand "generateTridactylManifest" {} ''
        #       cp "${builtins.fetchurl manifestURL}" "$out"
        #       sed -i.bak "s%REPLACE_ME_WITH_SED%${tridactyl-native}%" "$out"
        #     '';
        #   in "${pkgs.tridactyl-native}/lib/mozilla/native-messaging-hosts/tridactyl.json";

        # Use fixed profile name so it can be targeted in themes and scripts
        file."${localDir}/profiles.ini".text = ''
          [Profile0]
          Name=default
          IsRelative=1
          Path=${cfg.profileName}.default
          Default=1

          [General]
          StartWithLastProfile=1
          Version=2
        '';

        file."${localDir}/${cfg.profileName}.default/user.js" =
          mkIf (cfg.settings != {} || cfg.extraConfig != "") {
            text = ''
              ${concatStrings (mapAttrsToList (name: value: ''
                user_pref("${name}", ${builtins.toJSON value});
              '') cfg.settings)}
              ${cfg.extraConfig}
            '';
          };

        file."${localDir}/${cfg.profileName}.default/chrome/userChrome.css" =
          mkIf (cfg.userChrome != "") { text = cfg.userChrome; };

        file."${localDir}/${cfg.profileName}.default/chrome/userContent.css" =
          mkIf (cfg.userContent != "") { text = cfg.userContent; };
      };
  };
}
