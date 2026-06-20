# Log: Axiomctl CLI Consolidation

- Fetched latest remotes from the dirty detached main workspace and selected `origin/master` as the base ref.
- Created isolated worktree `.worktrees/axiomctl-cli-consolidation` on branch `legion/axiomctl-cli-consolidation-rust-cli` from `origin/master`.
- Contract decision: rename `axiom-mode` to `axiomctl`, keep broad dotfiles workflows in `hey`, and only move bounded Axiom host-control verbs with fixed argv into the Rust CLI.
- Renamed the Rust package path and metadata to `packages/axiomctl`, updated Axiom to install it with an injected `hey` path, and rewrote README usage around `axiomctl`.
- Implemented no-dependency command parsing for `axiomctl mode`, top-level `cli` / `desktop` / `status` aliases, and a bounded `reload` verb that runs fixed argv `hey reload`.
- Validation passed: rustfmt check, `.#axiomctl` package build, help output, Axiom host wiring/target eval, Axiom toplevel dry-run, current-reference stale grep, and `git diff --check`.
- Review-change passed with no blocking findings; security lens confirmed fixed target names and fixed argv for the `hey reload` bridge.
- Prepared implementation-profile walkthrough artifacts and PR body under `.legion/tasks/axiomctl-cli-consolidation/docs/`.
- Render handoff recorded as artifact-only/pending: the HTML exists at `.legion/tasks/axiomctl-cli-consolidation/docs/report-walkthrough.html`, but adding a Pages preview workflow is outside this task scope and no PR number exists yet.
- Wrote Legion wiki summary and updated current decisions, patterns, maintenance, index, and wiki log for the `axiomctl` boundary.
- Final lightweight checks passed after docs/wiki writeback: stale current-reference grep, HTML forbidden-pattern check, and `git diff --check`.
- Committed `feat(axiom): rename mode cli to axiomctl`, rebased on `origin/master`, pushed branch `legion/axiomctl-cli-consolidation-rust-cli`, and opened PR https://github.com/Thrimbda/dotfiles/pull/104.
