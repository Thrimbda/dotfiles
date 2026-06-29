# RFC Review: Aliyun Acorn Vaultwarden Dual Run

**Result: PASS**

## Decision

Implementation can begin. The RFC keeps the change host-local, preserves `acorn`, identifies the secret-recipient risk, requires a target decryptability check, and defines a rollback that removes only the new `aliyun-acorn` module/import/secret artifacts.

## Blocking Findings

None.

## Review Notes

- **Complexity**: Choosing a duplicated host-local module over a new shared/parameterized abstraction is appropriate for a secret-sensitive staged migration. The drift risk is acknowledged and bounded by the later cutover/removal work.
- **Assumptions**: The key assumptions are sufficiently recorded: the old acorn key is only a transient decrypt identity, and `/home/c1/.ssh/id_ed25519` matches the `aliyunAcorn` recipient used by `hosts/aliyun-acorn/secrets/secrets.nix`.
- **Rollback**: Rollback is credible because `acorn` remains unchanged and the PR can be reverted by removing the new target-host config, secret rule, and encrypted file.
- **Verification**: The planned Nix build/eval checks plus target decryptability check are enough to make implementation reviewable without printing secret plaintext.
- **Security/privacy**: The RFC explicitly rejects copying the old `.age` file, avoids plaintext persistence, and requires decrypting the new file with the target identity to catch wrong-recipient artifacts.

## Non-blocking Suggestions

- Make the implementation command for agenix explicit enough to avoid accidentally using the wrong `secrets.nix` rules file, e.g. run from `hosts/aliyun-acorn/secrets` or set `RULES=hosts/aliyun-acorn/secrets/secrets.nix`.
- Before staging, explicitly check that `./acorn_id_ed25519` and any transient plaintext files are not tracked or staged, and remove transient plaintext material after re-encryption.
- Expand shape verification if convenient to cover copied security/runtime parity beyond the current sample checks: `signupsAllowed = false`, `invitationsAllowed = true`, `loginRatelimitSeconds = 30`, nginx `forceSSL`/`enableACME`/body-size behavior, tmpfiles backup rules, and fail2ban jails.
- Keep deployment/cutover documentation clear that this PR is config-only; real traffic movement still needs DNS/ACME readiness and a data ownership or migration plan to avoid divergent vault data.
