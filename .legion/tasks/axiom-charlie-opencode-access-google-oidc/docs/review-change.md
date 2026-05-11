# Review Change: axiom/charlie opencode Cloudflare Access Google OIDC

## Verdict

PASS.

Security lens applied because this task changes identity/access policy for public opencode hostnames and stores an encrypted Cloudflare API credential. No blocking correctness, scope, verification, or security findings remain.

## Blocking Findings

None.

## Security Review

- Access policy shape matches the approved design: `docs/test-report.md:30-40` records the axiom Access app/policy creation and charlie policy update, and `docs/test-report.md:44-53` records final API assertions that both hostnames have exactly one self-hosted app, Google-only `allowed_idps`, exact-email allow policy entries for `c1@ntnl.io` and `siyuan.arc@gmail.com`, required Google `login_method`, and no broad/bypass/non-identity allow policy.
- The prior wiki blocker is resolved: `.legion/wiki/maintenance.md:28-29` no longer says axiom Access remains pending, and `.legion/wiki/decisions.md:71-77` now records current Google IdP enforcement, exact-email allowlist, and the need for new security review before broadening access.
- Secret handling matches the task constraints: `config/secrets/cloudflare-access.env.age` is present as the ops/config age secret, `config/secrets/secrets.nix:1-4` does not register it for global agenix deployment, and `docs/test-report.md:55-65` records plaintext staging absence and global map exclusion. Reviewed task/diff content did not expose plaintext Cloudflare API tokens or OIDC client secrets.

## Scope Compliance

PASS. The diff stays within the approved Cloudflare Access/evidence/docs scope: it updates directly relevant docs and Legion wiki current-truth entries, adds the encrypted ops credential, and does not modify opencode services, tunnel IDs, DNS routes, cloudflared connector modules, host deployments, or introduce Terraform/new auth schemes.

## Verification Sufficiency

PASS. API/CLI verification is sufficient for the control-plane requirements in this environment, and the skipped interactive browser checks are explicitly documented as manual validation in `docs/test-report.md:71-78`, consistent with the RFC allowance for unavailable user sessions (`docs/rfc.md:144-150`). Repository hygiene evidence includes `git diff --check` passing (`docs/test-report.md:67-69`).

## Non-Blocking Notes

- Manual browser smoke checks with both allowed accounts and one unlisted Google account remain recommended after deployment, but they are not blocking because the required API policy shape has been verified.
