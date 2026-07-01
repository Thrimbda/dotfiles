# Test Report

## Summary

PASS. The generated `aliyun-acorn` `sshd_config` now includes the intended `AuthorizedKeysFile` directive and no longer contains `GSSAPIAuthentication`. The generated `/etc/ssh/authorized_keys.d/c1` entry still exists.

## Commands

### Generated sshd_config

Command:

```sh
src=$(nix build --no-link --print-out-paths '.#nixosConfigurations.aliyun-acorn.config.environment.etc."ssh/sshd_config".source') && rg '^AuthorizedKeysFile %h/.ssh/authorized_keys /etc/ssh/authorized_keys.d/%u$' "$src" && ! rg -q '^GSSAPIAuthentication\b' "$src"
```

Result:

```text
AuthorizedKeysFile %h/.ssh/authorized_keys /etc/ssh/authorized_keys.d/%u
```

Exit status: 0.

Why this proves the claim: this builds the exact NixOS-generated `sshd_config` file for `nixosConfigurations.aliyun-acorn`, verifies the target `AuthorizedKeysFile` line is present, and fails if `GSSAPIAuthentication` remains in the generated file.

### Generated c1 authorized keys entry

Command:

```sh
nix eval --json '.#nixosConfigurations.aliyun-acorn.config.environment.etc."ssh/authorized_keys.d/c1"'
```

Result:

```json
{"enable":true,"gid":0,"group":"+0","mode":"0444","source":"/nix/store/gzdb92m53432c9gvyqwcpis9x8h2i535-c1-authorized_keys","target":"ssh/authorized_keys.d/c1","text":null,"uid":0,"user":"+0"}
```

Exit status: 0.

Why this proves the claim: it confirms NixOS still materializes `/etc/ssh/authorized_keys.d/c1`, so restoring `AuthorizedKeysFile` makes sshd read the already-generated key file again.

### Diff hygiene

Command:

```sh
git diff --check
```

Result: no output.

Exit status: 0.

## Skipped

- Remote deployment to `aliyun-acorn` was intentionally skipped because the contract only covers repository configuration and local Nix evaluation/build verification.
- Full system toplevel build was not run; the targeted generated-file build is the strongest low-cost proof for this specific SSH configuration regression.
