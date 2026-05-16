# Review Change: Axiom Sidra Apple Music

## Verdict

PASS.

## Blocking Findings

None.

## Scope Review

- In scope: root flake adds the Sidra input, `flake.lock` pins it, `modules/desktop/apps/sidra.nix` adds the desktop app module, and `hosts/axiom/default.nix` enables it.
- In scope: Legion task evidence was added under `.legion/tasks/axiom-sidra-apple-music/`.
- No QQ Music, NetEase Cloud Music, Cider, browser DRM, launcher favorite, audio stack, or unrelated desktop configuration changes were made.

## Correctness Review

- The module follows the existing desktop app pattern: `enable` option under `modules.desktop.apps`, optional package override, and installation through `user.packages`.
- The default Sidra package uses `hey.inputs.sidra.packages.${pkgs.stdenv.hostPlatform.system}.default`, matching the repository's flake-input access pattern and avoiding deprecated `pkgs.system` use in new code.
- The option defaults to `null` and only resolves Sidra's package when enabled, keeping disabled hosts from unnecessarily forcing the external package path.
- Verification evidence is strong for this change: `axiom` option eval returned `true`, and the `axiom` system toplevel built successfully with Sidra derivations in the closure.

## Security Lens

Applied because the change introduces a new external flake input.

- The Sidra source is pinned in `flake.lock` to commit `9e3525f5284bcabccc4d96acea264fb47d41172f` with a nar hash.
- The input follows the repository's existing `nixpkgs-unstable` input rather than introducing another independent nixpkgs baseline.
- No secrets, auth material, service privileges, sandbox permissions, firewall rules, or system services are added.
- Residual risk is normal supply-chain risk for an Electron/AppImage/deb-style desktop application; this is acceptable for the requested installation and remains bounded by the pinned flake lock.

## Non-blocking Notes

- Runtime Apple Music login/playback still depends on Apple's service and Sidra's upstream Widevine/session behavior; this was intentionally not automated.
