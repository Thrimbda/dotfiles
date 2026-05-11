# Test Report

## Summary

PASS. Focused Nix evaluation confirms `axiom` includes `feishu` in `user.packages`, and the `axiom` NixOS toplevel derivation evaluates successfully.

## Commands

1. `nix eval --json ".#nixosConfigurations.axiom.config.user.packages" --apply 'pkgs: builtins.map (p: p.pname or p.name or "") pkgs'`
   - Result: PASS
   - Evidence: output package names include `"feishu"`.
   - Output: `["aria2","autossh","feishu","git-lfs","htop","k9s","kubectl","nvtop","todesk","uv"]`

2. `nix eval --raw ".#nixosConfigurations.axiom.config.system.build.toplevel.drvPath"`
   - Result: PASS
   - Evidence: produced `/nix/store/vkyhi1hqpjislnhr00z9x068zz2wvd8m-nixos-system-axiom-25.11.20260203.e576e3c.drv`.

## Why These Checks

- The first command directly verifies the requested behavioral claim: `axiom` will install the Feishu client through its managed user package set.
- The second command verifies the host configuration still evaluates after adding the unfree Electron client package.

## Notes

- Nix emitted pre-existing evaluation warnings about `specialArgs.pkgs`, deprecated `mesa.drivers`, renamed `hardware.pulseaudio`, and renamed `system`; none are introduced by this change and none blocked evaluation.
- One eval-cache SQLite busy warning was ignored by Nix and did not prevent the toplevel derivation from being produced.

## Skipped

- No runtime launch or login test was run; this task only changes declarative package installation, and Feishu account/runtime behavior is out of scope.
