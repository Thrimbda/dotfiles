# Research: Cloudflare Access Google OIDC for axiom and charlie opencode

## Scope

This research supports the RFC for protecting the existing opencode Cloudflare Tunnel hostnames:

- `opencode-axiom.0xc1.space`
- `opencode-charlie.0xc1.space`

The task is limited to Cloudflare Access configuration and directly related evidence/documentation. It does not redesign the opencode services or cloudflared tunnel connectors.

## Repository Evidence

### Axiom

- `.legion/tasks/axiom-ssh-opencode-cloudflared-fix/docs/test-report.md` records that the axiom opencode tunnel and DNS route were created successfully.
- The same test report records Cloudflare Access for `opencode-axiom.0xc1.space` as not verified and still an external/manual follow-up.
- `.legion/wiki/decisions.md` currently says the axiom opencode exposure requires Cloudflare Access before the public hostname is safe for use.
- `.legion/wiki/maintenance.md` still includes a follow-up to verify Cloudflare Access for `opencode-axiom.0xc1.space`.

### Charlie

- `.legion/tasks/charlie-opencode-server-cloudflare-access/context.md` records that Cloudflare API automation previously created or confirmed a self-hosted Access application for `opencode-charlie.0xc1.space`.
- The same context records a prior allow policy for `c1@ntnl.io` only.
- The user has now expanded the required allowlist to `c1@ntnl.io` and `siyuan.arc@gmail.com`, so charlie needs reconciliation rather than being assumed complete.

### Local Credentials Surface

- `.gitignore` ignores a root-level `cloudflare` file, but no such file exists inside the new PR worktree.
- Environment presence checks found no `CLOUDFLARE_API_TOKEN`, `CF_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`, `CF_ACCOUNT_ID`, `CLOUDFLARE_ZONE_ID`, or `CF_ZONE_ID` in the current shell.
- Because no token or account ID is currently visible in the worktree environment, live Cloudflare mutation is blocked until credentials are provided.
- The user subsequently required the Cloudflare API credential to be written into age. After rebasing onto the current base, the repository already contains the canonical API token secret `hosts/charlie/secrets/cloudflare-api-token.age` with recipient rules in `hosts/charlie/secrets/secrets.nix`. This task should reuse that canonical secret and avoid adding a duplicate token under `config/secrets`.

## Cloudflare API Notes

Relevant Cloudflare Access API surfaces from public docs:

- List Access applications: `GET /accounts/{account_id}/access/apps`, with filters such as `domain` and `exact`.
- Access self-hosted applications have `domain`, `type = "self_hosted"`, `allowed_idps`, and `auto_redirect_to_identity` fields.
- `allowed_idps` restricts which identity providers users can select for an application; `auto_redirect_to_identity = true` requires only one allowed IdP.
- List identity providers: `GET /accounts/{account_id}/access/identity_providers`.
- Identity provider types include `google` and `oidc`. A Google OIDC source may therefore appear as a native Google provider or as generic OIDC configured against Google OAuth endpoints.
- Application policies can include exact email rules: `{ "email": { "email": "user@example.com" } }`.
- Application policies can require a specific login method: `{ "login_method": { "id": "<identity-provider-id>" } }`.
- Application-specific policies can be created or updated under `/accounts/{account_id}/access/apps/{app_id}/policies`.

## Design Implications

- Exact email rules are preferable to domain rules because the user asked for only two identities.
- App-level `allowed_idps` alone makes the Google IdP the only selectable login path, but policy-level `login_method` is a stronger verification point because the allow decision itself requires the IdP.
- The safest shape is therefore both:
  - application `allowed_idps = [google_idp_id]` and `auto_redirect_to_identity = true` where accepted by the API;
  - allow policy `include` with the two exact emails and `require` with the same Google provider ID.
- Creating a new Google/OIDC identity provider may require OAuth client secrets. If no suitable IdP already exists and secrets are unavailable, the correct result is a blocked handoff with manual setup steps, not a fake pass.
- Persisted evidence must be sanitized. Do not store raw API responses if they include token, client secret, tunnel credential, or session material.
- The Cloudflare API token may be persisted only as encrypted age material. Plaintext staging should stay in ignored files and be deleted after API use.

## Open Items for Implementation

- Determine the Cloudflare account ID and API token source without printing secret values.
- Confirm the canonical `hosts/charlie/secrets/cloudflare-api-token.age` exists and do not add a duplicate API token age file.
- List Access identity providers and identify the intended Google OIDC provider ID.
- List or create Access applications for both opencode hostnames.
- Reconcile each app's allow policy to exactly `c1@ntnl.io` and `siyuan.arc@gmail.com`, requiring the selected Google provider.
- Verify final state with sanitized app/policy summaries and, if feasible, browser checks for allowed and denied identities.
