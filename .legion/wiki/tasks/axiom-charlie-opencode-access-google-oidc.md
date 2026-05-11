# Axiom and Charlie Opencode Cloudflare Access Google OIDC

## Metadata

- `task-id`: `axiom-charlie-opencode-access-google-oidc`
- `status`: `active`
- `risk`: `high`
- `schema-version`: `2026-05-08-legion-workflow`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

Cloudflare Access now protects both opencode tunnel hostnames, `opencode-axiom.0xc1.space` and `opencode-charlie.0xc1.space`, with Google-only Access applications and exact-email allow policies for `c1@ntnl.io` and `siyuan.arc@gmail.com`.

API verification passed for app uniqueness, Google-only `allowed_idps`, required Google `login_method`, exact-email allow rules, and absence of broad/bypass/non-identity allow policies. Manual browser smoke checks with both allowed identities and one denied identity remain recommended.

The Cloudflare API credential used for the operation is covered by the canonical `hosts/charlie/secrets/cloudflare-api-token.age` secret from the current base; plaintext staging was removed, and this task does not add a duplicate config-level API token secret.

The canonical API token rotation risk remains tracked in maintenance. The user explicitly declined rotation in this task, so it is treated as an accepted follow-up risk rather than a blocker for the verified Access app/policy state.

## Reusable Decisions

- cloudflared ingress is transport only; Cloudflare Access is the authentication boundary for opencode public hostnames.
- Opencode Access apps should stay restricted to the Google identity provider and exact-email allow rules for `c1@ntnl.io` plus `siyuan.arc@gmail.com` unless a future task performs a new security review.
- Account-level Cloudflare API credentials should use a separate env-style age secret and stay separate from cloudflared tunnel runtime credentials. Avoid duplicate API token secrets; rotate the canonical token when exposure risk changes.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-charlie-opencode-access-google-oidc/plan.md`
- `research`: `.legion/tasks/axiom-charlie-opencode-access-google-oidc/docs/research.md`
- `rfc`: `.legion/tasks/axiom-charlie-opencode-access-google-oidc/docs/rfc.md`
- `rfc-review`: `.legion/tasks/axiom-charlie-opencode-access-google-oidc/docs/review-rfc.md`
- `test-report`: `.legion/tasks/axiom-charlie-opencode-access-google-oidc/docs/test-report.md`
- `change-review`: `.legion/tasks/axiom-charlie-opencode-access-google-oidc/docs/review-change.md`
- `report`: `.legion/tasks/axiom-charlie-opencode-access-google-oidc/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/axiom-charlie-opencode-access-google-oidc/docs/pr-body.md`
