{ lib, pkgs, ... }:
let
  retire = pkgs.writeShellScriptBin "retire-charlie-rustdesk" (builtins.readFile ./retire-rustdesk.sh);
in {
  # Run once after verifying the private desktop connection; preserve a local rollback.
  system.build.screenSharingTools = retire;
  environment.systemPackages = [ retire ];

  system.activationScripts.postActivation.text = lib.mkAfter ''
    echo "configuring Charlie screen sharing..." >&2
    screen_user_uuid=$(/usr/bin/dscl . -read /Users/c1 GeneratedUID | /usr/bin/awk '{print $2}')
    [ -n "$screen_user_uuid" ] || exit 1
    if ! /usr/bin/dscl . -read /Groups/com.apple.access_screensharing >/dev/null 2>&1; then
      /usr/sbin/dseditgroup -o create com.apple.access_screensharing
    fi
    /usr/bin/dscl . -create /Groups/com.apple.access_screensharing GroupMembership c1
    /usr/bin/dscl . -create /Groups/com.apple.access_screensharing GroupMembers "$screen_user_uuid"
    if /usr/bin/dscl . -read /Groups/com.apple.access_screensharing NestedGroups >/dev/null 2>&1; then
      /usr/bin/dscl . -delete /Groups/com.apple.access_screensharing NestedGroups
    fi
    /bin/launchctl enable system/com.apple.screensharing
    if ! /bin/launchctl print system/com.apple.screensharing >/dev/null 2>&1; then
      /bin/launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.screensharing.plist
    fi
    unset screen_user_uuid
  '';

}
