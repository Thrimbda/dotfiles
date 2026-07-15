# RustDesk Charlie Runtime Fix

> **Mode:** implementation
> **Verification:** PASS for generated artifacts, full Darwin build and store-bundle signature
> **Change review:** PASS for the Charlie runtime-fix PR
> **Candidate runtime:** NOT RUN

## What Failed

The first Charlie install left `com.carriez.RustDesk_server` unloaded in the active `gui/501` launchd domain. A manual bootstrap made the user job and IPC available, but the v7 helper then expected c1's primary-group metadata (`501:20`) while the actual RustDesk directory, socket and PID file were `501:0`.

As a result, v7 failed readiness before publishing a reservation and before resolving or reading the secret. It produced no current reservation, ready object or stamp. These are supplied runtime observations; the candidate activation has not yet been run.

## Minimal Fix

Production changes remain limited to `hosts/charlie/default.nix`:

- Both provision and finalizer validators now require `<c1 uid>:0` (observed as `501:0`) while retaining the existing object-type, non-symlink and `0700`/`0600` mode checks.
- After the current-boot agenix gate, activation checks whether `gui/501` exists, bootstraps the managed LaunchAgent only when its label is missing, and kickstarts it. A missing GUI domain remains a successful no-op.
- The provision marker moves from v7 to v8. The evaluated v8 revision is `charlie-rustdesk-provision-v4:651ace645ed239c51d10e99c7fa60559bf67a4c9a1ab8495f4d2f7afb8e9be26`; the legal prefix is preserved, but old v7 state cannot be reused as current.

The fix does not change secret handling, the one-attempt reservation ordering, password invocation, ready publication or manual-finalize rules.

## Evidence

- Exact generated provision, finalizer, `postActivation` and full activation syntax/lint checks: **PASS**.
- Validator differential and activation-order assertions: **PASS**.
- Full `aarch64-darwin` system build: **PASS** — `/nix/store/3yl4galgkg4xzpkn7nlsl7v9awjnpq46-darwin-system-25.11.ebec37a`.
- RustDesk 1.4.9 store bundle on Darwin: **PASS** — arm64, deep/strict codesign, Team `HZF9JMC8YN`, and Gatekeeper `Notarized Developer ID`.
- Change review: **PASS**, with no blocking finding.

This evidence proves build and immutable-artifact readiness only. It does **not** prove candidate activation, launchd runtime, TCC, remote authentication or finalization.

## Still Required After Merge

1. Complete required PR checks and merge, then switch Charlie only from a clean merged `origin/master`—never from this feature worktree.
2. Observe the candidate recovery path and exact `501:0` IPC/runtime identities; prove one v8 reservation and ready object with no stamp.
3. Verify destination signature and TCC Screen Recording, Accessibility and Input Monitoring, including actual screen and keyboard/pointer control.
4. From a fresh controller, pass the new-password positive test and wrong, old and cross-host negative tests.
5. Only after those checks, run the exact manual finalizer and prove stamp, ready removal, fast-skip and no second password attempt.

Evidence: [`test-report.md`](./test-report.md), [`review-change.md`](./review-change.md).
