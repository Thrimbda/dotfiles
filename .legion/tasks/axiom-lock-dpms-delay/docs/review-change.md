# Change Review: Lock-Scoped DPMS Timeout for Axiom

Review type: correctness, maintainability, scope, and session-lock security review.

## Blocking Findings

None. No correctness, security, maintainability, or scope blocker was found in the current worktree.

## Correctness Review

- `modules/desktop/caelestia-lock-dpms-timeout.patch:19-59` creates one non-reused timer per lock epoch. Unlock increments the epoch before clearing and destroying the active timer. `:81-91` requires current lock state, immutable epoch equality, and exact timer object identity before DPMS-off. A queued callback after unlock or rapid relock therefore cannot act on the new epoch or clear its active timer.
- The same patch observes the existing `WlSessionLock.locked` boundary at `:65-70`. Direct Lock IPC, the 900-second idle action, and `SessionManager`/logind each already assign that property in the pinned source, so the implementation converges on one state transition rather than duplicating lock commands.
- At `:98-109`, the wake monitor is enabled only for a timer-owned DPMS-off epoch. Input only sends the existing hard-coded `dpms on` action, leaves `locked` untouched, clears the ownership marker, and has no timer creation path. At `:52-58`, unlock restores DPMS only when that marker belongs to the prior epoch; early unlock has no DPMS-on side effect.
- `modules/desktop/caelestia-lock-dpms-timeout.patch:5-11` defaults the new typed value to `0`, while `hosts/axiom/modules/caelestia.nix:7-21` alone sets it to `60` through both declarative and mutable settings. Other hosts receive no timer, DPMS action, or wake monitor activation at the default value.

## Session-Lock Security Review

Security lens applied because this changes lock-adjacent behavior.

- The feature does not introduce an unlock path or a new privileged IPC endpoint. Its only new commands are fixed `dpms off` and `dpms on` actions through the existing Caelestia action seam.
- Wake input is guarded by the current `locked` state and epoch and never writes `locked = false`. Timer cancellation plus epoch and identity checks prevent an old lock's callback from blanking an unlocked or later-locked session.
- The remaining security-relevant uncertainty is runtime integration, not an apparent bypass in the source: a deployed session must still demonstrate that compositor DPMS wake leaves the `WlSessionLock` active.

## Validation And Test Wiring

- `modules/desktop/caelestia.nix:37-79` applies the same patch to the package and defines a `runCommand` test that copies `hey.inputs.caelestia-shell`, makes the copy writable, applies the patch with `--fuzz=0`, and runs `modules/desktop/tests/caelestia-lock-dpms-patch-test.js` against the patched copy. `flake.lock:72-87` pins that input to `046dd3c6c3b1782f27284d5fc0e181b6021dd7c7`.
- `modules/desktop/caelestia.nix:470-473` wires the test into `system.extraDependencies` for enabled Linux Caelestia configurations. The package override and test share the same patch path. The focused test asserts the relevant state-machine shape at `modules/desktop/tests/caelestia-lock-dpms-patch-test.js:24-62`.
- Review checks passed: staged and unstaged whitespace checks, `node --check` for the static test, and a zero-fuzz dry-run patch application against the pinned source. `docs/test-report.md:13-105` additionally records a successful ordinary Git-backed package build and effective Axiom configuration evaluation. No Nix build or deployment was rerun during this read-only review.

## Scope And Delivery State

- The four production changes are within the approved boundary: Axiom settings, the focused Caelestia patch, package/test wiring, and the focused static test. No lock client, logind command, Hypridle policy, suspend/hibernate action, or other-host setting was changed.
- The staged production blobs remain identical to the prior PASS review, and no unstaged diff touches `hosts/axiom/modules/caelestia.nix`, `modules/desktop/caelestia.nix`, `modules/desktop/caelestia-lock-dpms-timeout.patch`, or `modules/desktop/tests/caelestia-lock-dpms-patch-test.js`. The prior production conclusion therefore still passes.
- Delivery metadata now records completion: `.legion/tasks/axiom-lock-dpms-delay/tasks.md:5-22` marks phase three complete at 3/3, and `.legion/tasks/axiom-lock-dpms-delay/log.md:5-17` records validation, review, walkthrough, and wiki writeback as complete while retaining only post-deployment graphical smoke as pending. The PR body and delivery walkthrough are present.
- There are no untracked paths. The staged index contains the implementation, validation evidence, review, walkthrough, and wiki artifacts; the current in-scope `plan.md`, `log.md`, and this refreshed review have unstaged metadata updates and should be staged with the final delivery artifacts before commit.

## Residual Live-Session Risks

- No deployed graphical-session test has exercised direct IPC lock, the 900-second idle lock, or `loginctl lock-session` through actual logind signal delivery.
- Static checks cannot prove ext-idle notification delivery, Hyprland DPMS behavior on every connected display, or physical-input wake while the session remains locked.
- The live matrix should include early unlock, rapid unlock/relock, wake after feature-owned DPMS-off, and existing audio/Keep Awake inhibition to confirm the intended independent lock-scoped behavior in the running session.

PASS
