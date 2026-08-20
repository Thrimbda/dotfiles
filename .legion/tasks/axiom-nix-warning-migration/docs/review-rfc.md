# RFC Review: Axiom Nix Warning Migration

## Current Result: PASS

## Review 3: PASS

The explicit decision to disable Linux system Info documentation is user-approved, limited to the existing documentation-default policy, and reversible through either a host override or `git revert`. It removes the sole deterministic upstream Gawk build warning without patching package contents or altering cache behavior. Cache TLS retries remain correctly classified as external transport evidence.

## Review 2: PASS

The RFC now limits full Xorg activation to explicitly X11 desktop hosts, retains XKB values for Hyprland and console use, and explicitly preserves SSH askpass rather than relying on the former Xorg-derived default. Its validation plan checks all three rendered Axiom values.

The explicit boot and `sleep.target` fixture services preserve the deprecated test hook's two execution points and make the required resume ordering testable. Package-collision changes assign a single owner to each affected binary instead of broadly suppressing collision diagnostics. Rollback and external-diagnostic boundaries are clear.

## Review 1: FAIL

## Blocking Finding

The proposed Xorg collision fix removes `services.xserver.enable` from the shared Colemak module without preserving the behavior that currently follows from it.

`modules/desktop/hyprland.nix` reads the XKB values directly, so Axiom does not need a full Xorg server for its Wayland session. However, `programs.ssh.enableAskPassword` defaults to `config.services.xserver.enable`; removing the flag would silently disable the current SSH askpass behavior. The same shared Colemak module is enabled by Axiom, Azar, and Atlas, so an unconditional removal could also break a host that intentionally uses an X11 session.

This is blocking because the current RFC does not define a host-type guard, an explicit askpass policy, or a verification path for those behavior changes. The resulting implementation could remove more than duplicate system-path providers.

## Required Resolution

- Keep `services.xserver.xkb` settings available to Hyprland and console XKB.
- Enable the full Xorg server only for desktop types that actually require an X11 session.
- Explicitly preserve SSH askpass for desktop sessions rather than inheriting a changed default.
- Verify the rendered Axiom configuration has no full Xorg server package while the intended XKB and askpass values remain set.

## Non-Blocking Notes

- The explicit test-only boot/resume oneshot split is an appropriate replacement shape for `powerUpCommands`, provided the existing Bluetooth VM test proves stop-order behavior.
- External cache TLS retries and the Gawk Info direntry issue are correctly excluded from source-level remediation.
