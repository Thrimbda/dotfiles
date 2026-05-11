# Log

## 2026-05-11

- User reported that quickshell appeared unable to restart or modify Wi-Fi and that Catppuccin conflicted with Caelestia in file explorer and Fcitx5 surfaces.
- Legion workflow entry selected `brainstorm` because no existing task id/path was supplied.
- Live/read-only checks found the active visible shell is Caelestia Shell running as a `quickshell` process under `caelestia-shell.service`, not the old repository-managed `config/quickshell` stack.
- Live permission checks showed user `c1` is not in the `networkmanager` group; `nmcli general permissions` from the non-seat tool session reports Wi-Fi enable/disable as `no` and network control as `auth`; logind `CanReboot`, `CanPowerOff`, and `CanSuspend` report `challenge` outside the active graphical seat.
- Contract confirmed by user with scope covering both permissions and Catppuccin/Caelestia theme cleanup.
- Created Git worktree `.worktrees/axiom-caelestia-permissions-theme-cleanup` from `origin/master` on branch `legion/axiom-caelestia-permissions-theme-cleanup-perms-theme`.
- Wrote design RFC at `docs/rfc.md`. Recommended path is Axiom-local policy: add `c1` to the existing NetworkManager authorization group, add a narrow user-specific logind power-action polkit allowlist, replace Catppuccin visible icon/cursor assets, and disable the Axiom Fcitx5 Catppuccin override.
- RFC review passed with no blocking findings. Implementation must keep the logind action list literal and record live-session gaps for disruptive controls.
- Implemented Axiom-local configuration changes: added `networkmanager` to the evaluated `users.users.c1.extraGroups`, added a literal logind power-action polkit allowlist for the primary user, disabled the Axiom Fcitx5 Catppuccin theme override, and replaced Autumnal Catppuccin icon/cursor packages with Papirus/Bibata.
- Verification passed: targeted Axiom eval, `git diff --check`, and `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link` all succeeded. Live Wi-Fi/power/visual checks remain post-deploy smoke items because they are disruptive or require the switched graphical session.
- Review-change round 1 failed: logind polkit allowlist was user-specific but not local-subject-specific, which exceeded the local desktop shell authorization boundary. Returned to implementation to require `subject.local == true`.
- Implemented the review fix by requiring `subject.local == true` in the logind polkit allowlist.
- Re-verification passed after the review fix: targeted Axiom eval confirmed `polkitRequiresLocalSubject = true`, `git diff --check` passed, and the Axiom toplevel build passed again.
- Tightened the design/implementation further by removing the broad `networkmanager` group grant and adding a local primary-user fixed-action NetworkManager allowlist to the Axiom polkit rule.
- Final re-verification passed: targeted eval confirmed no `networkmanager` group grant, local-subject NetworkManager/logind allowlists, no prefix grants, unchanged NetworkManager+iwd ownership, Fcitx5 Catppuccin removal, Papirus/Bibata theme packages, `git diff --check` passed, and Axiom toplevel build passed.
- Review-change round 2 passed with no remaining blocking findings. Residual risk is live polkit subject classification for the Caelestia user service, which must be validated after deployment.
- Produced reviewer-facing walkthrough and PR body from existing RFC, verification, and review evidence.
- Completed Legion wiki writeback: added task summary and updated current decisions, patterns, maintenance, index, and wiki log.
