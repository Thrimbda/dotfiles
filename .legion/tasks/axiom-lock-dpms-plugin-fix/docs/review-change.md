# Change Review: Axiom Caelestia DPMS Plugin Closure Fix

Review type: correctness, maintainability, scope, and session-lock security.
Reviewed `plan.md`, `docs/rfc.md`, `docs/review-rfc.md`,
`docs/test-report.md`, the complete staged diff, and the empty tracked
unstaged diff. The test report is currently untracked and was reviewed as
delivery evidence.

## Blocking Findings

None.

## Correctness And Maintainability

- `modules/desktop/caelestia.nix:39-76` captures the unmodified plugin before
  either override, applies the Config-only patch to that plugin, and applies
  only the QML patch to the shell. This respects the separate upstream source
  filesets; the shell patch is an exact extraction of the pre-existing QML
  hunk, not a timer behavior change.
- The shell override compares resolved store paths, not names, at `:51-65`.
  It asserts exactly one original-plugin match and maps that one entry to the
  patched plugin, preserving every other `old.buildInputs` item. The recorded
  configured-package evaluation reports one patched input and zero original
  inputs. An independent review evaluation reproduced those counts.
- `:66-68` extends rather than replaces `old.passthru`. The resulting package
  and upstream package both expose `extras`, `m3shapesModule`, and `plugin`;
  the resulting `plugin` is the patched output.
- The configured shell output
  `/nix/store/8nls2lbjxsg378f8iy65lrdlpam36js0-caelestia-shell-1.0.0` directly
  references the patched plugin. A review-time
  `nix-store --query --requisites` check matched only
  `/nix/store/qnq2h0frlvlflak559zmy1y66zdd6br3-caelestia-qml-plugin`, not the
  original `/nix/store/0d7cv2q48b7d5fx7cc3bh27s1vvv1mvs-caelestia-qml-plugin`.
  The old plugin is therefore absent from the realized shell closure.
- The clean zero-fuzz patch applications, configured package build, and
  artifact test in `docs/test-report.md` provide appropriate build-time
  evidence. The built qmltypes artifact places `lockDpmsTimeout` with type
  `int` inside `caelestia::config::GeneralIdle` (lines 3267-3304), matching
  `modules/desktop/caelestia-lock-dpms-config.patch:4-11`.
- Non-Linux evaluation remains lazy. The original-plugin binding is demanded
  only by the Linux branches; forcing the module's package default with
  `hostSystem = "aarch64-darwin"` returned the non-Linux placeholder
  `/dummy/caelestia-shell-unavailable` even though that placeholder has no
  `plugin` attribute. No non-Linux Caelestia input is forced.

## Non-Blocking Follow-Up

- `modules/desktop/tests/caelestia-lock-dpms-patch-test.js:27-29` uses a
  pattern whose span can cross a later qmltypes `Component`, so a future file
  could theoretically satisfy the property portion from that later component.
  The current artifact inspection and independent source assertion establish
  the intended property for this change. Bound the match to the enclosing
  component when next hardening the focused test.

## Scope And Session-Lock Security

- The production diff is limited to the approved package override, split
  patches, and focused test. It does not change Axiom's `60` setting, the
  900/1800-second policy, Hypridle ownership, suspend/hibernate behavior,
  session runner, or another host's configuration.
- Security lens applied because the change is lock-adjacent. The new Config
  patch only adds a default-disabled typed property. The retained QML logic
  has no unlock assignment or new privileged IPC: expiry and input wake use
  the existing fixed DPMS actions, and the previous review's lock, epoch, and
  timer-identity guards remain unchanged.
- The test report correctly limits its claims to build-time closure alignment.
  It does not claim that a deployed QML engine selected this plugin or that
  physical DPMS behavior has occurred.

## Post-Deployment Runtime/Import-Path Residual

Not yet evidenced. After deployment and a Caelestia restart, record the
loaded `libcaelestia-configplugin.so` from the shell process (for example,
`/proc/<pid>/maps`), show it is under the patched plugin output, show the old
plugin path is absent, and confirm the active value remains `60`. Package
closure evidence cannot prove QML import-path selection in the live process.

## Manual DPMS Residual

Not yet evidenced. With the deployed session locked, wait 60 seconds, verify
DPMS turns off, then verify physical input wakes the display while
`WlSessionLock` remains locked. Do not claim this behavior until that manual
check has completed.

Implementation review is ready for deployment validation; deployment
acceptance remains pending the two residual checks above.

PASS
