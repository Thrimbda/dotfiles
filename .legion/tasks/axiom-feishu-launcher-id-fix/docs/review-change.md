# Change Review

## Verdict

PASS.

## Blocking Findings

None.

## Scope Review

- In scope: `hosts/axiom/default.nix` changes the Feishu launcher favourite from the `.desktop` filename to the Quickshell desktop-entry id `bytedance-feishu`.
- In scope: the existing mutable-config migration removes the legacy `bytedance-feishu.desktop` favourite and appends `bytedance-feishu` if missing.
- No Feishu account/cache/proxy/autostart data, credential, secret, organization policy, launcher architecture, or non-Axiom host behavior changed.

## Correctness Review

- Quickshell derives desktop-entry ids from the complete base name of the desktop file, so `bytedance-feishu.desktop` becomes `bytedance-feishu`.
- The evaluated Caelestia favourite now matches the discovered app id.
- The migration preserves unrelated favourites while replacing the old incorrect Feishu value.
- Feishu remains package-provided through the upstream desktop file.

## Verification Review

- Focused evals confirm the corrected favourite id, desktop file availability, pre-start hook presence, migration script syntax, migration jq behavior, Axiom toplevel evaluation, and whitespace.

## Residual Risk

- Live visual confirmation still depends on the running Axiom Wayland launcher UI, but the live config was manually updated and `caelestia-session` restarted for immediate smoke testing.
