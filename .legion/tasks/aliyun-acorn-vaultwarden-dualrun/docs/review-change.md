# Change Review: Aliyun Acorn Vaultwarden Dual Run

**Stage**: review-change
**Result**: PASS

## Blocking Findings

None.

## Review Summary

- The staged production diff is limited to the accepted dual-run scope: `hosts/aliyun-acorn/default.nix`, `hosts/aliyun-acorn/modules/vaultwarden.nix`, `hosts/aliyun-acorn/secrets/secrets.nix`, and `hosts/aliyun-acorn/secrets/vaultwarden-env.age`.
- `hosts/acorn` has no staged changes, and the shared `modules/services/vaultwarden.nix` remains unchanged.
- The new `aliyun-acorn` module matches the accepted host-local shape: it enables `modules.services.vaultwarden`, declares `age.secrets.vaultwarden-env` as `vaultwarden:vaultwarden` with mode `0400`, preserves the `vault.0xc1.space` nginx routes, and keeps backup/tmpfiles behavior aligned with `acorn`.
- Verification evidence is credible after staging: the test report records post-staging plain `.#` eval/build passes, and reviewer spot checks confirmed the target service/secret/vhost shape plus `acorn` still enabled.

## Security Lens

Security review was applied because this change handles secrets and encrypted secret material.

- No private key file or plaintext secret file is staged; staged path review shows only the intended `.age` secret artifact and task documentation.
- A staged-content scan for private-key and env-secret markers found no matches in the changed files.
- `hosts/aliyun-acorn/secrets/secrets.nix` declares `"vaultwarden-env.age".publicKeys = [ aliyunAcorn ];`.
- `hosts/aliyun-acorn/secrets/vaultwarden-env.age` is present, staged as an encrypted binary artifact, and reviewer decryptability check with `/home/c1/.ssh/id_ed25519` succeeded with output redirected to `/dev/null`.
- The review did not print or inspect secret plaintext.

## Residual Risks

- No live deployment was performed; `vaultwarden.service`, `nginx.service`, `fail2ban.service`, ACME issuance, and `/run/agenix/vaultwarden-env` ownership still need post-deploy checks.
- Dual-running the same `vault.0xc1.space` service can diverge Vaultwarden data if traffic is split without an explicit data migration/ownership plan.
- ACME may fail on `aliyun-acorn` until DNS or routing points the domain at that host.
- The decryptability check proves the target key can decrypt the file, but intentionally does not validate or reveal the secret contents.
