# RFC: Expose Feishu Desktop Entry To Caelestia App Discovery

## Status

Accepted by `review-rfc`.

## Context

Axiom already installs `pkgs.feishu` and declares `bytedance-feishu.desktop` in Caelestia `launcher.favouriteApps`. The launcher still does not show Feishu, which means the favourite id is not enough: the app database must first discover the desktop entry.

Upstream Caelestia launcher evidence:

- `modules/launcher/services/Apps.qml` builds the app list from `DesktopEntries.applications.values` and then sorts through `AppDb`.
- `plugin/src/Caelestia/appdb.cpp` only sorts and filters provided entries; it does not scan package paths itself.
- Quickshell `src/core/desktopentry.cpp` scans `$XDG_DATA_HOME/applications`, then each `$XDG_DATA_DIRS` element with `/applications` appended.
- If `XDG_DATA_DIRS` is missing, Quickshell falls back to `/usr/local/share:/usr/share`, which does not contain Nix store desktop entries such as Feishu's `share/applications/bytedance-feishu.desktop`.

Current local evidence:

- `caelestia-shell.service` has an explicit `path` containing user and system packages, but its `environment` does not set `XDG_DATA_DIRS`.
- Generated Hyprland/UWSM environment currently exports `PATH` and Qt/session variables, not `XDG_DATA_DIRS`.

## Decision

Set `XDG_DATA_DIRS` for Axiom's `caelestia-shell.service` to the `share` paths of the evaluated user packages plus system packages.

This exposes existing package-provided desktop entries to the exact process that runs Quickshell/Caelestia app discovery. It keeps the previous Feishu favourite config intact and avoids creating a duplicate desktop entry.

## Alternatives

### Duplicate Feishu Desktop Entry

Create a repo-owned desktop file under a path Caelestia already scans.

- Pros: narrow to Feishu.
- Cons: duplicates upstream metadata, can drift from package `Exec`, `Icon`, locale names, and categories, and still requires ensuring the directory is scanned.

### Session-Wide `XDG_DATA_DIRS`

Export/import `XDG_DATA_DIRS` through generated UWSM/Hyprland session startup.

- Pros: helps every GUI process in the session.
- Cons: broader behavioral surface than this task needs and harder to prove no unrelated launcher/app behavior changes.

### Caelestia Module-Wide `XDG_DATA_DIRS`

Set the service environment in `modules/desktop/caelestia.nix` for every host enabling the module.

- Pros: generally correct for a shell that owns app discovery.
- Cons: affects any future or existing non-Axiom Caelestia host. This task is scoped to Axiom's Feishu launcher regression.

## Implementation Shape

- Add an Axiom-local `caelestiaLauncherDataDirs` value using `makeSearchPath "share"` over `config.users.users.${config.user.name}.packages ++ config.environment.systemPackages`.
- Add `systemd.user.services.caelestia-shell.environment.XDG_DATA_DIRS = caelestiaLauncherDataDirs` in `hosts/axiom/default.nix`.
- Leave `launcher.favouriteApps` and the mutable `shell.json` updater unchanged.

## Verification

- Evaluate Axiom `caelestia-shell.service.environment.XDG_DATA_DIRS` and prove one element is the Feishu package `share` path.
- Evaluate that `modules.desktop.caelestia.settings.launcher.favouriteApps` still contains `bytedance-feishu.desktop`.
- Evaluate that Feishu remains in Axiom user packages.
- Evaluate/build the Axiom toplevel derivation.
- Run whitespace checks.

## Rollback

Remove the Axiom-local `XDG_DATA_DIRS` service environment assignment. Feishu remains installed and the previous favourite configuration remains as before, but the launcher may again fail to discover package desktop entries if no other environment source provides them.
