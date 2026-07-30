# RFC: Persistent unattended DP-4 capture

## Status

Proposed. This is a medium-risk Axiom-only runtime change because it grants the
trusted local user limited access to the root-owned RustDesk configuration.

## Evidence

- The live Axiom `~/.config/hypr/xdph.conf` contains
  `custom_picker_binary = /nix/store/...-axiom-rustdesk-portal-picker`; that
  immutable picker emits `[SELECTION]/screen:DP-4`.
- The active c1 XDPH process is `xdg-desktop-portal-hyprland 1.3.12`, has
  `XDG_CONFIG_HOME=/home/c1/.config`, and its ScreenCast portal reports version
  5. Its logs show successful Wayland and PipeWire initialization.
- The active RustDesk root service starts a UID c1 `rustdesk --server` child
  with `HOME=/root` and `XDG_CONFIG_HOME=/root/.config`. c1 cannot traverse
  `/root` (mode `0700`) or write the RustDesk config.
- RustDesk 1.4.9's `libs/scrap/src/wayland/pipewire.rs` uses ScreenCast for a
  running service. At portal version 4 or later it requests `persist_mode=2`,
  stores `wayland-restore-token` through `LocalConfig`, and resends that token
  on subsequent capture requests.

The picker is therefore sufficient to make the first screen request select
DP-4, but the server child cannot persist the resulting restore token. Each
new incoming session can consequently fall back to a fresh selection request.

## Options

### A. Add a dedicated virtual output

Rejected. XDPH would still see the physical outputs, while selecting the
virtual output would expose a separate empty desktop rather than the existing
DP-4 session.

### B. Move RustDesk to c1's home directory

Rejected. This breaks the existing root-owned storage invariant and couples
system service state, password provisioning, and the interactive tray state.

### C. Preserve root password storage and isolate `RustDesk2.toml` for c1 (chosen)

Keep the root service, its environment, and the root-owned config path. After
each RustDesk service start, make only the non-secret `RustDesk2.toml`
user-owned by c1. c1 gets execute-only traversal through the parent root
directories and write/execute access to the RustDesk config directory. Set the
directory sticky so c1 can atomically replace its own `RustDesk2.toml` but
cannot remove or rename root-owned sibling files.

This permits the actual `--server` process to persist the non-secret portal
restore token that RustDesk already implements. It does not change display
layout, authentication options, network settings, or the existing XDPH fixed
picker.

## Design

1. Define an immutable `rustdeskStateAccess` script in Axiom's existing
   RustDesk local bindings.
2. Run it as `ExecStartPre` of `rustdesk.service`, before every service start
   and the existing provisioning-triggered restart. The c1 `--server` process
   must be able to read a previously saved restore token during its startup.
3. The script creates the root config directory and an empty `RustDesk2.toml`
   only when absent. RustDesk 1.4.9 stores permanent-password material in the
   root-owned `RustDesk.toml`; `RustDesk2.toml` contains the server/options
   configuration where the Wayland restore token is stored. It applies:
   - c1 execute-only traversal on `/root` and `/root/.config`;
   - sticky mode plus c1 write/execute ACL on `/root/.config/rustdesk` for
     RustDesk's atomic update;
   - `c1:c1 0600` ownership on `RustDesk2.toml` only.
4. Keep the existing XDPH picker output exactly `screen:DP-4`. A new incoming
   session receives DP-4 without a chooser; RustDesk saves the portal token and
   later sessions restore it without selecting again.

The access change is deliberately limited to the same single-owner c1 trust
boundary already accepted by the RustDesk task. It does mean c1 can replace
only its local options file, so it must not be generalized to another account.

## Verification

- Evaluate the Axiom service to confirm its original environment and command
  line are unchanged and the ACL pre-start script is present.
- Deploy only from the merged `origin/master` baseline, then restart
  `rustdesk.service` and verify c1 owns and can write `RustDesk2.toml`, while
  `RustDesk.toml` remains inaccessible and root-owned.
- From the remote client, establish a new unattended connection. No Axiom-side
  chooser may appear and the captured output must be DP-4.
- Establish a second new connection after a RustDesk restart. Confirm the
  restore token remains present and DP-4 is selected without interaction.
- Confirm the active XDPH config remains the existing fixed picker and that
  Hyprland monitor declarations and RustDesk public/auth options are unchanged.

## Rollback

Revert the Axiom pre-start script and deploy the reverted configuration.
Because ACLs and ownership are mutable state, stop RustDesk, remove c1's three
ACL entries with `setfacl -x`, restore the config directory to `0700`, and
change `RustDesk2.toml` back to `root:root 0600`. The root-owned password file,
portal picker, and monitor layout remain intact.

## External Documentation

Context7's RustDesk documentation query failed with `fetch failed`; the public
search provider also rate-limited the request. The decision above is based on
the pinned RustDesk 1.4.9 source and live Axiom portal/process evidence.
