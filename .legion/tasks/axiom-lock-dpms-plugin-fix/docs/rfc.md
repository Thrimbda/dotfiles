# RFC: Axiom Caelestia DPMS Plugin Closure Fix

Status: Proposed | Risk: Standard

## Context And Evidence

`modules/desktop/caelestia.nix` currently applies the combined
`caelestia-lock-dpms-timeout.patch` through an outer
`upstreamShellPackage.overrideAttrs`. The patch contains both the Config C++
property in `plugin/src/Caelestia/Config/generalconfig.hpp` and the lock timer
QML in `modules/IdleMonitors.qml`. Axiom sets `lockDpmsTimeout = 60` through
both declarative and mutable Caelestia settings.

Recorded live evidence establishes a closure mismatch:

- The deployed shell `/nix/store/41531...-caelestia-shell-1.0.0` contains the
  QML lock-timeout patch, and the active configuration has `60`.
- Its runtime plugin reference is
  `/nix/store/0d7...-caelestia-qml-plugin`.
- `nix derivation show` for that plugin proved `patches=""` and an upstream
  plugin source, so it does not provide `lockDpmsTimeout`.

The outer override patches only the shell derivation. The shell's separately
built `plugin` passthru dependency remains the old plugin, which is what QML
loads at runtime. Therefore the QML and configuration schema are from different
derivations; this is the root cause of lock-time failure.

## Goals

- Make the Config plugin that the shell actually loads expose
  `lockDpmsTimeout`.
- Make replacement of the shell's plugin dependency explicit, exact, and
  inspectable.
- Preserve the existing lock-scoped timer state machine and Axiom's current
  configuration.

## Non-goals

- Changing timer behavior, the 900/1800-second idle policy, or suspend and
  hibernate semantics.
- Enabling the feature or changing effective behavior on other hosts.
- Adding Hypridle, a wrapper, or any other idle owner.

## Options

| Option | Assessment | Decision |
| --- | --- | --- |
| Apply the existing combined patch to the plugin. | Invalid: the plugin fileset lacks `modules/IdleMonitors.qml`, so the QML hunk cannot apply there. | Reject. |
| Add a wrapper or runtime import-path workaround. | Hides the closure mismatch, makes import selection less deterministic, and leaves the package contract unverified. | Reject. |
| Split the C++ Config and shell QML patches; patch the plugin with the C++ part; replace the shell's exact old plugin dependency; expose it through `passthru.plugin`. | Each hunk applies to the derivation that builds it, and the package closure has one auditable plugin identity. | Recommend. |

## Decision

Replace the combined patch with two focused patches:

- The Config patch changes only `generalconfig.hpp` and is applied by
  `upstreamShellPackage.plugin.overrideAttrs`.
- The shell patch changes only `IdleMonitors.qml` and is applied by the outer
  shell override. Its timer logic must be a mechanical extraction of the
  current QML hunk, not a behavior change.

Capture the original plugin before either override. In the outer shell override,
map the main package's `buildInputs` and replace an input only when its resolved
store path equals the original plugin's resolved store path. Do not match by
name. Require exactly one match; zero or multiple matches must fail evaluation
instead of silently appending a second plugin. Preserve every other build input.

Set the resulting shell's `passthru.plugin` to the patched plugin while
preserving other passthru attributes. This makes the exposed plugin identity and
the dependency used to build the shell agree.

## Correctness Criteria

| Property | Required proof |
| --- | --- |
| Schema and QML align | The built patched plugin's `qmltypes` contains `lockDpmsTimeout`; the built shell contains the unchanged timer QML hunk. |
| Exact dependency replacement | The original plugin store path is absent from the shell's `buildInputs`; the patched plugin store path replaces it exactly once. |
| Public package identity | `package.passthru.plugin` resolves to the patched plugin output. |
| Runtime closure alignment | The deployed shell resolves the patched plugin, not `/nix/store/0d7...-caelestia-qml-plugin`, for the Caelestia.Config import. |
| Behavioral boundary | Axiom remains at `60`; its 900-second lock and 1800-second DPMS on/off entries, other hosts, and Caelestia-only idle ownership are unchanged. |

## Scope

Implementation is limited to the Caelestia package override, the split patches,
and focused patch/closure tests under `modules/desktop/`. The existing Axiom
settings remain unchanged. No wrapper, session-control, idle-policy, or
other-host change is in scope.

## Verification

Verification is planned; this RFC does not claim a completed build or deployed
smoke test.

- Apply each split patch with `--fuzz=0` to its own pinned upstream source.
  Keep the current QML state-machine assertions and add a plugin-focused check
  for the generated `qmltypes` property.
- Evaluate the configured Axiom package and assert that the original plugin
  path has zero `buildInputs` matches, the patched path has one replacement,
  and `passthru.plugin` is the patched output. Assert both Axiom settings still
  equal `60` and the 900/1800 policy and idle ownership are unchanged.
- Perform a full configured Caelestia package build on an approved build host.
  Inspect its plugin `qmltypes` and the shell dependency/reference information
  rather than accepting static QML source as proof.
- After deployment, restart Caelestia and confirm the active shell and loaded
  plugin store paths are from the new closure, the active configuration still
  has `lockDpmsTimeout = 60`, and the old plugin is not selected.
- Manually lock the deployed session, wait 60 seconds, and verify DPMS off then
  input wake while the session stays locked. Do not automate an unlock or claim
  this session check until it is performed.

## Rollback

For an immediate behavioral rollback, set `lockDpmsTimeout = 0` in both Axiom
settings paths, deploy, and restart Caelestia while retaining the patched plugin
schema. This disables the timer without recreating a schema/closure mismatch.

For a package-integration rollback, revert the shell QML patch, Config plugin
override, `buildInputs` replacement, and `passthru.plugin` update as one coupled
change, or deploy a known prior generation. Before removing Config schema
support, remove the persisted mutable `general.idle.lockDpmsTimeout` key as well
as the declarative setting; otherwise a retained `60` can outlive the property.
