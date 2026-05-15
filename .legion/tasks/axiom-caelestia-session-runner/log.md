# Log

- 2026-05-15: Diagnosed current Caelestia PID under `user@1000.service/session.slice/caelestia-shell.service`; `pkcheck` for NetworkManager Wi-Fi action returned `Not authorized`.
- 2026-05-15: Chose session-owned runner over polkit widening to preserve the existing local-subject security boundary.
- 2026-05-15: Implemented `caelestia-session` and moved Axiom shell lifecycle off `caelestia-shell.service`.
- 2026-05-15: Migrated implementation into `.worktrees/axiom-caelestia-session-runner` after the main workspace was incorrectly used first.
- 2026-05-15: Re-ran worktree validation and recorded results in `docs/test-report.md`.
