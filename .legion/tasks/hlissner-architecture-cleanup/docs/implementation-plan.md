# Implementation Plan

## Milestone 1: Baseline and Zero-output Cleanup
### Scope
- `.legion/tasks/hlissner-architecture-cleanup/**`
- `modules/desktop/default.nix`
- Comment-only cleanup in narrowly selected source files

### Steps
- [ ] Check current diff and avoid unrelated user changes.
- [ ] Remove unused local bindings or clearly stale comments that do not affect Nix evaluation.
- [ ] Keep any useful operational warning in place rather than deleting it for tidiness.

### Verification
- `git diff --check`
- Review diff to confirm only comments/dead local bindings changed.

### Rollback Notes
- Revert the zero-output cleanup slice if any changed expression has unclear behavior.

---

## Milestone 2: Platform/Env Helper Cleanup
### Scope
- `default.nix`
- `modules/home.nix`
- `modules/desktop/default.nix`
- `modules/desktop/hyprland.nix`
- `modules/desktop/caelestia.nix`
- Optional `_`-prefixed internal helper under `modules/desktop/`

### Steps
- [ ] Reuse `mkEnvVars` where it preserves current Linux/Darwin env targets exactly.
- [ ] Add an internal desktop env constants helper only if it reduces duplicated Hyprland/Caelestia constants without broad rewrites.
- [ ] Update Hyprland and Caelestia call sites to consume constants while preserving generated file paths and values.
- [ ] Confirm helper file is skipped by recursive module import.

### Verification
- `nix eval .#hostMetadata` or equivalent host metadata eval.
- Targeted eval/inspection of `environment.sessionVariables`, `hypr/custom/env.conf`, `uwsm/env`, and `caelestia-shell.service.environment` for Axiom.
- Confirm Darwin base still imports no desktop modules.

### Rollback Notes
- Revert helper file and call sites as one slice if generated env surfaces drift unexpectedly.

---

## Milestone 3: Host Path Normalization
### Scope
- `hosts/axiom/default.nix`
- `hosts/charlie/default.nix`
- Optional exact-equivalence literals in `hosts/charles/default.nix` or `hosts/azar/default.nix`

### Steps
- [ ] Replace safe hardcoded current-user home paths with `config.user.home` or a local derived variable.
- [ ] Keep service names, users, ports, bind hosts, tunnel endpoints, secret paths and log destinations equivalent.
- [ ] Do not introduce reusable service modules.

### Verification
- Evaluate or inspect Axiom systemd unit strings for opencode/autossh.
- Evaluate or inspect Charlie launchd `ProgramArguments`, `HOME`, `WorkingDirectory`, and log paths if touched.
- Search diff for unchanged reverse SSH ports, opencode port `4096`, Cloudflare hostnames, and secret file paths.

### Rollback Notes
- Revert host path normalization if exact-equivalence cannot be demonstrated.

---

## Milestone 4: Verification and Delivery
### Scope
- `.legion/tasks/hlissner-architecture-cleanup/docs/test-report.md`
- `.legion/tasks/hlissner-architecture-cleanup/docs/review-change.md`
- `.legion/tasks/hlissner-architecture-cleanup/docs/report-walkthrough.md`
- `.legion/tasks/hlissner-architecture-cleanup/docs/pr-body.md`
- `.legion/wiki/**`

### Steps
- [ ] Run the most credible local Nix/static validation available.
- [ ] Record results and skipped runtime checks in `docs/test-report.md`.
- [ ] Complete readiness review.
- [ ] Generate walkthrough and PR body.
- [ ] Create PR but do not merge.
- [ ] Write back durable decisions/patterns to Legion wiki.

### Verification
- PR URL exists.
- Review/change evidence exists.
- Wiki writeback is present.

### Rollback Notes
- If PR remains unmerged and blocked, record blocked state and keep/cleanup worktree according to user direction.
