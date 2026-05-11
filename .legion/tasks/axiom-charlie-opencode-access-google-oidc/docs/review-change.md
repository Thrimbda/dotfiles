# Review Change: axiom/charlie opencode Cloudflare Access Google OIDC

## Verdict

PASS.

Security lens applied because this task changes identity/access policy for public opencode hostnames and handles Cloudflare API credentials. No blocking correctness, scope, verification, or security findings remain for this task's readiness.

## Blocking Findings

None.

## Security Review

- Access policy shape matches the approved design: `docs/test-report.md:30-40` records the axiom Access app/policy creation and charlie policy update, and `docs/test-report.md:44-53` records final API assertions that both hostnames have exactly one self-hosted app, Google-only `allowed_idps`, exact-email allow policy entries for `c1@ntnl.io` and `siyuan.arc@gmail.com`, required Google `login_method`, and no broad/bypass/non-identity allow policy.
- Documentation/wiki state is aligned with the verified Access boundary: `.legion/wiki/maintenance.md:28-29` no longer says axiom Access remains pending, and `.legion/wiki/decisions.md:71-77` records current Google IdP enforcement, exact-email allowlist, and the need for new security review before broadening access.
- Rebase-aligned secret handling matches the current task contract: the canonical API token secret is `hosts/charlie/secrets/cloudflare-api-token.age`, registered by `hosts/charlie/secrets/secrets.nix:1-5`; no duplicate `config/secrets/cloudflare-access.env.age` is present; no root `cloudflare` plaintext staging file is present in the reviewed worktree; and `docs/test-report.md:55-65` records the same hygiene checks.
- The Cloudflare API token rotation risk is documented as pre-existing and explicitly accepted by the user as a separate maintenance risk (`docs/test-report.md:71-75`, `.legion/wiki/maintenance.md:32-34`). It is not a blocker for this task because the task did not introduce the exposure, the user declined rotation in this scope, no plaintext token is committed by this task, and the Access app/policy state being delivered is independently verified. The residual risk remains real and should be addressed by the tracked maintenance follow-up.

## Scope Compliance

PASS. The diff stays within the approved Cloudflare Access/evidence/docs/wiki scope: it reconciles the two Access apps/policies, updates task and wiki evidence, reuses the canonical Cloudflare API token age secret, removes the duplicate config-level secret, and does not modify opencode services, tunnel IDs, DNS routes, cloudflared connector modules, host deployments, Terraform, or identity scope beyond the two approved emails.

## Verification Sufficiency

PASS. API/CLI verification is sufficient for the control-plane requirements in this environment, including selected Google IdP, app uniqueness, app `allowed_idps`, exact-email policy include rules, required Google login method, and absence of broad/bypass/non-identity allow policy (`docs/test-report.md:9-65`). Skipped interactive browser checks are explicitly documented as manual validation (`docs/test-report.md:71-79`), consistent with the RFC allowance for unavailable user sessions (`docs/rfc.md:143-149`). Repository hygiene evidence includes `git diff --check` passing (`docs/test-report.md:67-69`).

## Non-Blocking Follow-Ups

- Run manual browser smoke checks with both allowed Google accounts and one unlisted denied account.
- Rotate the canonical Cloudflare API token later if/when the user chooses to close the accepted maintenance risk.
