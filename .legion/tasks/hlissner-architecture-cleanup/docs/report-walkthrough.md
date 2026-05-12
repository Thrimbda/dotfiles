# Reviewer Walkthrough: Hlissner-aligned Architecture Cleanup

> **Mode**: implementation
> **Branch**: `legion/hlissner-architecture-cleanup-clean-boundaries`
> **PR**: https://github.com/Thrimbda/dotfiles/pull/43
> **Worktree**: `.worktrees/hlissner-architecture-cleanup`
> **Design**: `docs/rfc.md`
> **Verification**: `docs/test-report.md`
> **Readiness Review**: `docs/review-change.md`

## What Changed
- Added Legion task evidence for the architecture cleanup, including research, RFC, RFC review, implementation plan, test report and readiness review.
- Reused the existing `mkEnvVars` helper for platform-specific env emission in `default.nix` and `modules/home.nix`.
- Added `modules/desktop/_env.nix` as an internal constants helper for shared Wayland/QT env values used by Hyprland and Caelestia.
- Removed an unused local env helper from `modules/desktop/default.nix`.
- Normalized exact-equivalent host-local home paths in Axiom, Azar, Charlie and Charles through `config.user.home` and derived local variables.

## What Did Not Change
- No `flake.nix` or `flake.lock` changes.
- No flake input upgrades.
- No secret content or secret path changes.
- No Cloudflare tunnel ID, hostname, ingress service, opencode port, SSH reverse port or bind-host changes.
- No desktop product change; Axiom remains Hyprland + UWSM + Caelestia Shell.
- No new opencode/autossh/cloudflared public service module was introduced.

## Review Order
1. Read `docs/rfc.md` for scope and alternatives; the selected path is boundary-preserving helper/path cleanup.
2. Review `modules/desktop/_env.nix`, `modules/desktop/hyprland.nix`, and `modules/desktop/caelestia.nix` together to confirm env values are centralized without changing generated config paths.
3. Review `default.nix` and `modules/home.nix` for `mkEnvVars` usage.
4. Review `hosts/axiom/default.nix`, `hosts/azar/default.nix`, `hosts/charlie/default.nix`, and `hosts/charles/default.nix` for path normalization only.
5. Check `docs/test-report.md` and `docs/review-change.md` for validation and readiness evidence.

## Validation Evidence
- `git diff --check` passed.
- `nix eval .#hostMetadata --json` passed.
- Axiom generated Hyprland env, UWSM env and Caelestia service env evaluated with expected Wayland/QT values.
- Axiom/Azar Linux service paths and Charlie/Charles Darwin paths evaluated to the same expected current-user paths.
- `_env.nix` non-import check returned `false` for `config ? waylandSessionVariables`, proving the helper is not accidentally loaded as a module.
- `nix build --option eval-cache false .#nixosConfigurations.axiom.config.system.build.toplevel --dry-run` passed.

## Known Limits
- Live Axiom Hyprland/Caelestia smoke was not run in this environment.
- Live Darwin launchd/opencode smoke was not run in this environment.
- Nix emitted existing evaluation warnings documented in `docs/test-report.md`; no new blocker was found.

## PR Lifecycle Note
- User explicitly requested that the PR not be automatically merged. This PR should be reviewed and checked, but auto-merge must remain disabled.
