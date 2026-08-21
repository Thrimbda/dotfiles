# RFC Review: Axiom Caelestia DPMS Plugin Closure Fix

Review type: adversarial standard-risk design gate. This review inspected the
pinned `caelestia-shell` revision `046dd3c6c3b1782f27284d5fc0e181b6021dd7c7`
and performed evaluation-only attribute checks; it did not build or deploy.

## Blockers

None.

## Findings

- The split is feasible and correctly follows the upstream derivation boundary.
  Upstream `nix/default.nix:92-110` builds `plugin` from a fileset containing
  `plugin/`, while the shell at `nix/default.nix:133-172` builds from the full
  source and has `plugin` as both a direct `buildInputs` member and a
  `passthru` field. Therefore the Config-only hunk applies to the plugin
  source, and the QML-only hunk applies to the shell source; the combined patch
  cannot apply to the plugin fileset.
- The current evaluated Axiom package has exactly one direct plugin input,
  `/nix/store/0d7cv2q48b7d5fx7cc3bh27s1vvv1mvs-caelestia-qml-plugin`, and its
  `passthru` contains `plugin`, `extras`, and `m3shapesModule`. An
  evaluation-only candidate confirmed that `old.buildInputs` and
  `old.passthru` are available in this package's `overrideAttrs` lambda. It
  produced zero old-plugin matches, one replacement match, and retained the
  other passthru fields.
- Capture the original plugin before either override. Match with
  `builtins.toString input == builtins.toString originalPlugin`, count the
  matches, and assert the count is one before returning the override attrs.
  This compares resolved output paths rather than names or derivation-value
  equality. Use the patched plugin derivation as the replacement value; only
  the comparison should coerce to a store path. Extend
  `old.passthru` with `plugin = patchedPlugin` so `package.plugin` and the
  build input identify the same output.
- The generated artifact is testable at
  `plugin/lib/qt-6/qml/Caelestia/Config/caelestia-config.qmltypes`. The
  `CONFIG_GLOBAL_PROPERTY` macro emits a Qt `Q_PROPERTY`, and upstream's QML
  registrar already records the existing `GeneralIdle` properties there. A
  built-plugin qmltypes assertion is thus a valid schema-build proof, but it
  is not proof of which module the running QML engine selected.
- Import selection remains an explicit runtime concern, not a reason to add a
  wrapper. `Caelestia.Config/qmldir` declares an optional plugin and a
  preferred resource path, so two plugin roots can still be ambiguous by
  import-path order. The RFC's final deployed assertion is sufficient only if
  it records the actual loaded
  `libcaelestia-configplugin.so` path for the restarted shell process (for
  example from `/proc/<pid>/maps`) and proves it is under the patched plugin
  output, with the old path absent. `buildInputs`, `passthru.plugin`, or a
  closure-reference check alone cannot prove runtime selection.
- The planned verification sequence is adequate when it retains all three
  layers: clean split-patch application to each source fileset, a built-plugin
  qmltypes check plus exact build-input/passthru/reference assertions, and the
  post-restart loaded-library check with the active value still `60`. The
  manual lock, 60-second DPMS, wake-with-lock-retained check remains correctly
  separate and must not be claimed before it is performed.
- Immediate rollback is sound: write `0` through both Axiom settings paths
  while retaining the patched schema, then restart Caelestia. For a package
  rollback, the persisted mutable key needs an explicit deletion step because
  the current mutable-config writer deep-merges and does not delete arbitrary
  settings. The pinned old Config loader iterates known Qt properties, so an
  unknown retained key is ignored rather than loaded, but deleting it before a
  coupled source rollback remains the correct documented cleanup.

PASS
