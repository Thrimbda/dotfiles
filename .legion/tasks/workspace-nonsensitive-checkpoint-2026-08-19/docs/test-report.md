# Verification Report: Workspace Non-Sensitive Checkpoint

## Result

PASS. The isolated worktree contains the requested versionable workspace state, excludes known local credentials and worktree metadata, evaluates the migrated Axiom filesystem labels, and passes diff hygiene.

## Commands And Evidence

### Import parity

```bash
git diff --binary | sha256sum
sha256sum <main-safe-file> <worktree-safe-file>
```

The initial tracked diff SHA-256 matched between the main workspace and isolated worktree. Each of the five reviewed untracked source documents also matched its worktree copy byte-for-byte. After independent review, the three user-approved regression clusters were restored from `origin/master`; all remaining imported content is unchanged.

### Staged-path boundary

```bash
git diff --cached --name-only
git status --short --untracked-files=all
```

The final staged snapshot contains only approved implementation, evidence, documentation, and wiki paths. It contains none of `acorn_id_ed25519`, `acorn_password`, `resent_key`, `.worktrees/`, or the mutable Fcitx profile outside the repository.

### Sensitive-pattern scan

```bash
patterns=(
  'BEGIN ([A-Z0-9 ]+ )?PRIVATE KEY'
  '(gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,})'
  'AKIA[0-9A-Z]{16}'
  'sk-(proj-)?[A-Za-z0-9_-]{20,}'
  're_[A-Za-z0-9_-]{20,}'
  'eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}'
)
for regex in "${patterns[@]}"; do
  ! git diff --cached --no-color --unified=0 | rg -q "$regex"
done
```

No staged addition matched private-key headers, GitHub tokens, AWS access keys, OpenAI keys, Resend keys, or JWT-shaped values. Fixed-output Nix hashes and generic documentation references to passwords or secrets were retained because they are not credentials.

### Axiom filesystem evaluation

```bash
nix eval --raw .#nixosConfigurations.axiom.config.fileSystems."/".device
nix eval --raw .#nixosConfigurations.axiom.config.fileSystems."/boot".device
nix eval --impure --raw --expr '(builtins.elemAt (builtins.getFlake "path:$PWD").nixosConfigurations.axiom.config.swapDevices 0).device'
nix eval --json .#nixosConfigurations.axiom.config.modules.desktop.hyprland.hypridle.enable
```

Results:

```text
/dev/disk/by-label/nixos-2t
/dev/disk/by-label/AXIOM2T
/dev/disk/by-label/swap-2t
false
```

This proves the migrated disk labels are rendered while Axiom retains the merged single-idle-owner policy.

### Review remediation

```bash
git diff --quiet origin/master -- \
  .legion/ledger.csv \
  .legion/tasks/axiom-hyprland-xwayland-idle-crash-fix \
  .legion/wiki/decisions.md \
  .legion/wiki/maintenance.md \
  .legion/wiki/patterns.md \
  .legion/wiki/tasks/axiom-caelestia-idle-timeouts.md \
  .legion/wiki/tasks/axiom-hyprland-xwayland-idle-crash-fix.md \
  .legion/wiki/tasks/axiom-remove-default-keep-awake.md \
  .legion/wiki/tasks/axiom-remove-idle-suspend.md \
  .legion/wiki/tasks/axiom-remove-never-sleep.md
! git diff --unified=0 origin/master -- \
  .legion/wiki/index.md \
  .legion/wiki/log.md | rg '^-[^-]'
git diff origin/master -- hosts/axiom/default.nix
```

The #166 task/wiki evidence and #167/#168 ledger/wiki records are preserved. Index and wiki-log changes only add the new checkpoint entry; they remove no prior records. The only Axiom host configuration changes are the three migrated filesystem labels; `hypridle.enable = false` is preserved.

### Diff hygiene

```bash
git diff --cached --check
```

Result: exit 0.

## Skipped

No full NixOS toplevel build was run. The executable configuration delta is limited to already-evaluated Axiom option values; the remaining changes are documentation and Legion state. No Acorn-local build or deployment is permitted.
