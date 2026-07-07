# Test Report: Acorn Aliyun Host Profile Rename

## Summary

PASS

The scoped validation confirms that the renamed host is exposed as `acorn`, the old `aliyun-acorn` host attr is absent, the nested image flake targets the renamed host, and active source files no longer contain stale `aliyun-acorn` references.

## Commands

### Host attr presence

Command:

```sh
nix eval --json --no-write-lock-file --apply 'configs: { acorn = builtins.hasAttr "acorn" configs; aliyunAcorn = builtins.hasAttr "aliyun-acorn" configs; }' .#nixosConfigurations
```

Result:

```json
{"acorn":true,"aliyunAcorn":false}
```

### Hostname evaluation

Command:

```sh
nix eval --raw --no-write-lock-file .#nixosConfigurations.acorn.config.networking.hostName
```

Result:

```text
acorn
```

### Image flake system

Command:

```sh
nix eval --raw --no-write-lock-file './hosts/acorn/image#aliyun-image.system'
```

Result:

```text
x86_64-linux
```

### Image build dry-run

Command:

```sh
nix build --dry-run --no-write-lock-file './hosts/acorn/image#aliyun-image'
```

Result: passed. Nix planned the `nixos-disk-image` closure for `nixos-system-acorn-efi-qcow2-25.11.20260203.e576e3c` without evaluation errors.

### Diff hygiene

Command:

```sh
git diff --check
```

Result: passed with no whitespace errors.

### Stale active reference search

Command:

```sh
if rg -n "aliyun-acorn|aliyunAcorn|nixosConfigurations\\.aliyun-acorn|hosts/aliyun-acorn" "hosts" --glob "*.nix" --glob "*.md"; then exit 1; fi
```

Result: passed with no matches in active host source/docs.

## Why These Checks

- The attr-presence and hostName evaluations prove the directory rename changed the active flake identity to `acorn` and removed `aliyun-acorn` as an active host attr.
- The image flake eval and dry-run cover the nested `hosts/acorn/image` consumer that previously extended `nixosConfigurations.aliyun-acorn`.
- The stale reference search covers the highest-risk mechanical rename failure mode while intentionally excluding historical `.legion` records.
- `git diff --check` catches patch hygiene issues before review.

## Skipped

- No remote deployment, Aliyun API call, DNS change, Terraform operation, or live service validation was run; these are explicitly out of scope.
