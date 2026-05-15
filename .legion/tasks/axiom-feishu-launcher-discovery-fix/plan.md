# Axiom Feishu Launcher Discovery Fix

## Name

Axiom Feishu Launcher Discovery Fix

## Task ID

`axiom-feishu-launcher-discovery-fix`

## Goal

Make Feishu discoverable by the Axiom Caelestia launcher so the existing `Super+Space` app surface can show and launch the upstream `bytedance-feishu.desktop` entry.

## Problem

Previous work installed Feishu and added `bytedance-feishu.desktop` to Caelestia `launcher.favouriteApps`, including a narrow mutable-config updater. The user still reports that Feishu is missing from the launcher. That means the remaining failure is likely not the favourite list itself, but Caelestia or Quickshell app discovery not seeing the desktop entry or the XDG data directory that contains it.

## Acceptance

- Feishu's upstream desktop entry id, `bytedance-feishu.desktop`, is visible to the app discovery path used by Axiom's Caelestia launcher.
- The fix is repository-owned and applies to Axiom without requiring a hand-written user desktop entry.
- The existing Caelestia launcher favourite configuration and mutable `shell.json` preservation behavior remain intact.
- Feishu remains installed on Axiom.
- The change does not manage Feishu account state, cache, proxy, autostart, credentials, organization policy, or other host behavior.
- Focused Nix/service/app-discovery validation passes, or any blocker is recorded with a clear reason and follow-up.

## Assumptions

- `Super+Space` opens the Caelestia launcher drawer in the current Axiom session.
- `bytedance-feishu.desktop` is still the upstream desktop entry id shipped by the Nixpkgs `feishu` package.
- Caelestia launcher favourites can reference a desktop id, but they do not by themselves make that id discoverable if the app database cannot scan the desktop entry.
- Static validation can prove generated configuration and service environment shape, but live launcher rendering still needs a real Axiom Wayland session after deployment.

## Constraints

- Follow Legion workflow and the `git-worktree-pr` envelope for repository modifications.
- Keep main workspace read-only except workflow prep and final refresh.
- Keep scope limited to Axiom Feishu desktop-entry or XDG data exposure and task evidence.
- Preserve user-mutable Caelestia `shell.json` and the existing `axiom-caelestia-keep-awake-default` behavior.
- Do not rework launcher favourites as the main fix.
- Do not touch Feishu runtime/account data, proxy, cache, autostart, credentials, organization policy, secrets, or non-Axiom hosts.

## Risks

- Caelestia or Quickshell may read desktop entries through an upstream app database path that differs from standard XDG lookup, requiring source inspection before choosing the minimal fix.
- Adding broad session environment changes could affect unrelated GUI app discovery if not scoped carefully.
- Headless validation cannot prove the live `Super+Space` menu updates until the fix is deployed into the real graphical session.

## Scope

- `hosts/axiom/default.nix` if Axiom-specific package, service, or environment exposure is needed.
- `modules/desktop/caelestia.nix` if the Caelestia shell service environment or app discovery inputs need a reusable local integration fix.
- `modules/desktop/hyprland.nix` only if the session environment import path is proven to be the missing desktop-entry discovery boundary.
- `.legion/tasks/axiom-feishu-launcher-discovery-fix/**` for task evidence.
- `.legion/wiki/**` for closing writeback.

## Non-Goals

- Do not replace Caelestia launcher with another launcher.
- Do not create duplicate Feishu desktop entries unless the upstream entry is proven unavailable to discovery and no smaller XDG exposure fix exists.
- Do not change Feishu login, account, cache, proxy, autostart, credential, organization policy, or runtime state.
- Do not change other hosts' launcher behavior.
- Do not overwrite existing user Caelestia `shell.json` contents.

## Design Summary

- First inspect the current Caelestia/Quickshell app discovery path, including how desktop entries are discovered and which environment variables the systemd user service receives.
- Prefer the smallest Axiom-owned fix that exposes Feishu's existing desktop entry through standard XDG data lookup to the Caelestia shell process.
- Keep the previous `launcher.favouriteApps` and pre-start favourite updater as supporting configuration rather than treating it as sufficient evidence of discoverability.
- Validate through focused Nix evals of package presence, service environment, generated launcher configuration, app-discovery inputs, and Axiom toplevel evaluation.

## Phases

1. Contract: materialize this task contract and checklist.
2. Design gate: inspect discovery source and decide whether this is low-risk design-lite or needs an RFC before implementation.
3. Implementation: apply the minimal Axiom-scoped discovery/XDG exposure fix in an isolated worktree.
4. Verification: run focused validation and record evidence.
5. Review and delivery: run change review, walkthrough, wiki writeback, PR lifecycle, cleanup, and main-workspace refresh.

---

*Created: 2026-05-15 | Last updated: 2026-05-15*
