## Summary

- move Axiom root, EFI, and swap configuration to the new 2TB disk labels
- preserve completed auth-mini-gateway pin evidence and add the hey/c1ctl native-status inventory
- checkpoint only reviewed non-sensitive workspace state while excluding credentials, local worktrees, and mutable user state
- retain the merged Axiom single-idle-owner policy and #166/#167/#168 audit history after review remediation

## Verification

- evaluated Axiom root: `/dev/disk/by-label/nixos-2t`
- evaluated Axiom boot: `/dev/disk/by-label/AXIOM2T`
- evaluated Axiom swap: `/dev/disk/by-label/swap-2t`
- evaluated `modules.desktop.hyprland.hypridle.enable`: `false`
- confirmed remediated Legion paths match `origin/master`
- passed `git diff --cached --check`
- passed excluded-path and staged credential-pattern scans

## Security

No credential files, private keys, API-key files, nested worktrees, or mutable Fcitx profile are included. Manual staged-diff review and common private-key/token pattern scans found no credential-like additions.

## Testing Gap

No full NixOS toplevel build was run. The executable change is limited to evaluated filesystem labels; the rest of the PR is documentation and Legion evidence.
