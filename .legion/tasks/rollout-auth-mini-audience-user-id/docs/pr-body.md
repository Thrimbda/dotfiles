# Roll out audience-bound gateway user IDs

## Summary

- Pin `auth-mini-gateway` to merged upstream `e1ea3e77fc39612b7418a3a44db5e2cc2b8618d4`.
- Migrate both Axiom and Acorn encrypted gateway environments from email allowlist authorization to the user-supplied exact auth-mini user ID.
- Preserve existing gateway cookie secrets and agenix recipient boundaries.
- Set Axiom cleartext proxy gateways to `UPSTREAM_PROTOCOL=http1`, required by the new gateway startup contract.
- Keep auth-mini, nginx, FRP, Cloudflare, firewall, protected upstreams, and session databases unchanged.

The supplied user ID is present only inside encrypted age payloads and is intentionally absent from repository docs and this PR body.

## Validation

- `nix build --no-link -L .#packages.x86_64-linux.auth-mini-gateway` — passed, including 119 library + 50 proxy integration tests.
- Axiom and Acorn secret decrypt/transform/re-encrypt/decrypt assertions — passed.
- Agenix owner/mode evaluation for both hosts — `auth-mini-gateway`, `0400`.
- Plaintext repository scan for the supplied user ID — no match.
- `git diff --check` — passed.

See `.legion/tasks/rollout-auth-mini-audience-user-id/docs/test-report.md` and `docs/review-change.md`.

## Rollout

After merge, deploy Axiom and Acorn from refreshed `origin/master`. Acorn must use the mandated Axiom build-host `nixos-rebuild` path; no Nix build or rebuild may run on Acorn.
