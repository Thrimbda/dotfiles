# RFC Review: Lock-Scoped DPMS Timeout for Axiom

Review type: adversarial standard-risk design gate. No live graphical-session claim was made or evaluated.

## Prior Blockers Resolved

- The action seam is now concrete: the patch adds the typed setting in `plugin/src/Caelestia/Config/generalconfig.hpp` and uses `modules/IdleMonitors.qml`'s existing `handleIdleAction` for both `dpms off` and `dpms on` (`docs/rfc.md:39-42`). This preserves a single Caelestia DPMS path without a host wrapper.
- The 1800-second monitor is no longer expected to wake a 60-second timer-owned blank. A disabled-by-default `IdleMonitor` with `timeout: 0` and `respectInhibitors: false` is enabled only after timer-owned DPMS off, wakes through `handleIdleAction("dpms on")`, preserves `locked`, and does not re-arm (`docs/rfc.md:67-72`). This matches the documented input-based `IdleMonitor` model.
- Direct IPC, the 900-second idle action, and `SessionManager.onLockRequested`/`loginctl lock-session` are all mapped to the same observed `root.lock.lock.locked` false-to-true transition, with source assertions and a later live check required (`docs/rfc.md:47-52,88-93`).
- Each lock epoch now owns a dynamically created, non-reused timer with an immutable epoch token and object-identity guard. Unlock invalidates the epoch and destroys the active timer, so an old queued callback cannot match a new lock's state (`docs/rfc.md:56-69`).
- Axiom is the only host that enables the setting in both declarative and mutable settings paths. The shared source patch remains inert at default `0`, and the rollback explicitly handles the persisted deep-merged key before property removal (`docs/rfc.md:43,76-82,95-99`).

## Non-Blocking Residual Risks

- Source/static checks can prove the patch shape, configuration, and guard wiring, but cannot prove ext-idle-notify delivery, compositor DPMS behavior, or physical display wake. The RFC correctly limits those to the specified later graphical-session checks.
- The preserved independent 1800-second monitor can still issue its own DPMS action during a lock epoch. The design intentionally does not couple it to the new timer; the later live check should confirm the actions remain non-disruptive and the lock stays active.
- The source seam and SessionManager mapping are tied to the pinned Caelestia revision. The required patch-application and source assertions must fail closed if that revision changes.

PASS
