set -eu

marker=/Applications/.RustDesk.app.nix-owner
if [ ! -f "$marker" ] || ! /usr/bin/grep -qx 'owner=rustdesk-self-hosted-remote-access' "$marker"; then
  exit 0
fi
# Only retire the repository-managed installation after the replacement is live.
if ! /usr/bin/nc -G 3 -z 127.0.0.1 5900; then
  echo "Charlie screen sharing is unavailable; retaining managed RustDesk" >&2
  exit 1
fi
backup=/var/db/mac-screen-sharing/rustdesk-backup
/bin/mkdir -p "$backup"
/bin/chmod 0700 /var/db/mac-screen-sharing "$backup"
if [ ! -e "$backup/previous-system" ]; then
  /nix/var/nix/profiles/default/bin/nix-store --add-root "$backup/previous-system" --indirect -r "$(/usr/bin/readlink /run/current-system)"
fi
if [ -e "$backup/RustDesk.app" ]; then
  echo "RustDesk backup already exists; refusing to overwrite it" >&2
  exit 1
fi
for job in com.carriez.RustDesk_provision com.carriez.RustDesk_service; do
  if /bin/launchctl print "system/$job" >/dev/null 2>&1; then
    /bin/launchctl bootout "system/$job"
  fi
done
uid=$(/usr/bin/id -u c1)
if /bin/launchctl print "gui/$uid/com.carriez.RustDesk_server" >/dev/null 2>&1; then
  /bin/launchctl bootout "gui/$uid/com.carriez.RustDesk_server"
fi
for plist in /Library/LaunchDaemons/com.carriez.RustDesk_service.plist \
  /Library/LaunchDaemons/com.carriez.RustDesk_provision.plist \
  /Library/LaunchAgents/com.carriez.RustDesk_server.plist; do
  if [ -e "$plist" ] || [ -L "$plist" ]; then
    /bin/cp -L "$plist" "$backup/$(/usr/bin/basename "$plist")"
    /bin/rm "$plist"
  fi
done
if [ -d /Applications/RustDesk.app ]; then
  /bin/mv /Applications/RustDesk.app "$backup/RustDesk.app"
fi
/bin/mv "$marker" "$backup/nix-owner"
if [ -d /var/db/rustdesk-provision ]; then
  /bin/mv /var/db/rustdesk-provision "$backup/provision-state"
fi
echo "Managed Charlie RustDesk retired; rollback files are in $backup"
