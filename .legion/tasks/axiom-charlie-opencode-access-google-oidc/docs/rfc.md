# RFC: Protect axiom and charlie opencode with Cloudflare Access Google OIDC

## 1. Context

`axiom` and `charlie` both expose a local-only `opencode-server` through Cloudflare Tunnel hostnames. The transport side is already present:

- `opencode-axiom.0xc1.space` routes to axiom's `http://127.0.0.1:4096` backend.
- `opencode-charlie.0xc1.space` routes to charlie's `http://127.0.0.1:4096` backend.

The remaining security boundary is Cloudflare Access. Prior axiom evidence explicitly left Access as an external follow-up. Prior charlie evidence says an Access app/policy exists for `c1@ntnl.io`, but the user now requires both hostnames to use Google OIDC and allow exactly:

- `c1@ntnl.io`
- `siyuan.arc@gmail.com`

This task makes the Access layer the deliverable. A working tunnel hostname without Access is not acceptable. The user also requires the Cloudflare API credential used for this change to be covered by age-encrypted repository secret management, with no plaintext committed.

## 2. Decision

Use Cloudflare Access self-hosted applications for both hostnames, constrained to a single Google identity provider and an exact-email allow policy.

Final intended state for each hostname:

- Application type: `self_hosted`.
- Domain: exactly one of the two opencode hostnames.
- Identity provider: a Cloudflare Access provider representing Google OIDC, either native `google` or generic `oidc` configured against Google OAuth/OIDC endpoints.
- Application `allowed_idps`: only the selected Google provider ID.
- Application `auto_redirect_to_identity`: enabled when the API accepts it, because only one IdP should be selectable.
- Policy decision: `allow`.
- Policy include rules: exact email rules for `c1@ntnl.io` and `siyuan.arc@gmail.com`.
- Policy require rules: `login_method` matching the selected Google provider ID.
- Broad domain, everyone, service-token-only, bypass, and non-identity policies are not part of the desired state for these hostnames.
- The Cloudflare API credential is kept in the canonical age-encrypted API-token secret `hosts/charlie/secrets/cloudflare-api-token.age`; this task does not add a duplicate API token secret.

## 3. Alternatives Considered

### Option A: Access app plus exact-email policy only

This would create/update a self-hosted Access app and allow the two emails with `{ email: { email } }` include rules.

Rejected as insufficient by itself because it does not guarantee which configured IdP is used when multiple identity providers are available in the Cloudflare account.

### Option B: Application `allowed_idps` only

This would restrict the login page to Google OIDC and rely on email rules to authorize users.

Rejected as a standalone control because policy evidence would not directly prove the allow decision requires the selected provider.

### Option C: Application `allowed_idps` plus policy `login_method` requirement

Recommended. This gives an application-level UX/security restriction and a policy-level authorization requirement. It is slightly more explicit but remains minimal and auditable.

### Option D: Add a second Cloudflare API token under `config/secrets`

Rejected for this task. The current base already has `hosts/charlie/secrets/cloudflare-api-token.age` as the dedicated API automation token. Adding another encrypted copy under `config/secrets` would increase rotation burden and ambiguity.

### Option E: Reuse the canonical host-local Cloudflare API token secret

Recommended for the user's age requirement. Reuse `hosts/charlie/secrets/cloudflare-api-token.age`, keep it separate from `cloudflared-credentials.age`, and avoid creating another API token secret in this task.

## 4. Scope

### In Scope

- Discover existing Access apps for `opencode-axiom.0xc1.space` and `opencode-charlie.0xc1.space`.
- Discover configured Google identity providers in Cloudflare Access.
- Create missing self-hosted apps only when no matching app exists.
- Update existing matching apps in place when safe.
- Create or update application-specific allow policies to match the exact two-email plus Google login-method requirement.
- Update task evidence and directly relevant docs/wiki maintenance entries that currently say axiom Access is still a follow-up.

### Out of Scope

- Changing tunnel IDs, DNS routes, cloudflared ingress, opencode service units, or local host deployment.
- Adding Terraform or another persistent Cloudflare IaC layer.
- Creating or storing Google OAuth client secrets in this repository.
- Storing plaintext Cloudflare API tokens in this repository.
- Adding opencode application-layer authentication.
- Allowing whole domains, Google groups, or all Zero Trust users.

## 5. Implementation Plan

### Step 1: Credential-safe discovery

- Check only whether Cloudflare credential variables exist; never print token values.
- If credentials are absent, request a plaintext staging file in a gitignored location and delete it after API verification.
- If credentials are present or decryptable from the canonical age file, use Cloudflare API calls that output sanitized summaries only.

### Step 1a: Age credential handling

- Use the existing canonical secret `hosts/charlie/secrets/cloudflare-api-token.age` and recipient rules in `hosts/charlie/secrets/secrets.nix`.
- Do not add `config/secrets/cloudflare-access.env.age` or any other duplicate API-token secret in this task.
- The accepted plaintext staging shape may use `API_TOKEN` / `ACCOUNT_ID`; commands normalize those names only in process and do not commit plaintext.
- Do not commit the plaintext staging file, command output containing token values, or decrypted env content.

### Step 2: Identify Google OIDC provider

- List Access identity providers with `GET /accounts/{account_id}/access/identity_providers`.
- Select an IdP whose type is `google`, or whose type is `oidc` and whose non-secret config identifies Google OAuth/OIDC endpoints.
- If multiple plausible Google providers exist, stop for user selection rather than guessing.
- If none exists and no Google OIDC client secret is available, block with manual setup instructions.

### Step 3: Reconcile applications

For each hostname:

- Query `GET /accounts/{account_id}/access/apps?domain=<hostname>&exact=true`.
- If one matching self-hosted app exists, preserve its app ID and update only Access-relevant fields.
- If none exists, create a self-hosted app for the hostname.
- If multiple apps match the same hostname, stop and document the conflict.
- Set `allowed_idps` to the selected Google provider ID.
- Enable `auto_redirect_to_identity` when only one provider is allowed and the API accepts the field.

### Step 4: Reconcile allow policy

For each app:

- List application policies.
- Prefer updating an existing app-specific allow policy that already owns this opencode hostname intent.
- If no suitable allow policy exists, create one.
- Ensure `decision = "allow"`, `include` contains exactly the two requested email rules, and `require` contains the selected Google `login_method` rule.
- Remove or replace unsafe broad allow conditions from the managed policy. If other policies could still allow access broadly, record them as blockers unless they are explicitly non-matching or deny-only.

### Step 5: Documentation and evidence

- Write a sanitized `docs/test-report.md` with commands, pass/fail status, app IDs, provider type/name, policy IDs, allowed emails, and blocker status.
- Record the canonical age file path, but not the decrypted token value.
- Update repository docs only where they currently describe the Access state or manual follow-up for these hostnames.
- Do not commit raw API responses containing secrets or redacted secret fields unless sanitized.

## 6. Verification Plan

Minimum API/CLI verification:

- Identity provider list shows exactly one selected Google-compatible provider for this task.
- Both hostnames have exactly one matching Access self-hosted application.
- Both applications have `allowed_idps` limited to the selected provider.
- Both applications have an allow policy with exact email include rules for `c1@ntnl.io` and `siyuan.arc@gmail.com`.
- Both policies require `login_method` for the selected Google provider.
- No matching broad allow/bypass policy remains for either app.
- `hosts/charlie/secrets/cloudflare-api-token.age` exists as the canonical API token secret and no duplicate `config/secrets/cloudflare-access.env.age` exists in this task.
- Plaintext staging is absent from both the main workspace and PR worktree after API verification.

Optional runtime verification if interactive login is available:

- `c1@ntnl.io` can authenticate through Google and reach the Access prompt/application.
- `siyuan.arc@gmail.com` can authenticate through Google and reach the Access prompt/application.
- An unlisted Google account is denied by Access.

If runtime browser verification is not possible in this environment, record it as skipped manual verification rather than marking it passed.

## 7. Rollback

Before mutation, capture a sanitized pre-change summary of each matching app and policy:

- app ID, domain, `allowed_idps`, and `auto_redirect_to_identity`;
- policy ID, decision, include/require/exclude rule shapes, and precedence.

Rollback paths:

- If an app was newly created by this task and should be abandoned, delete or disable that Access app.
- If an existing app was updated, restore its prior `allowed_idps`, `auto_redirect_to_identity`, and policy rule shape from the sanitized pre-change summary.
- If a new policy was created on an existing app, delete that policy or set it to deny while preserving safer existing policies.
- If credentials are unavailable for rollback, provide exact Cloudflare console steps and identify which app/policy IDs need reverting.
- If the age credential should be revoked after rollback, rotate the token tracked by `hosts/charlie/secrets/cloudflare-api-token.age` rather than adding another secret.

Rollback does not require changing cloudflared tunnel routes or opencode services because this task does not modify them.

## 8. Failure Handling

- Missing Cloudflare credentials: stop before mutation and document required credential names/scopes.
- Missing plaintext credential staging file and missing decryptable age credential: stop before mutation and document the required env file shape.
- Missing Google provider: stop before app/policy changes unless user supplies or confirms OIDC client setup.
- Multiple candidate Google providers: stop and ask user to choose the provider.
- Multiple Access apps for one hostname: stop and document conflict; do not create a third app.
- Existing broad allow/bypass policy remains: block delivery until removed, narrowed, or explicitly accepted by the user.
- API rejects `auto_redirect_to_identity`: proceed only if `allowed_idps` and `login_method` still enforce Google OIDC; record the field-level limitation.

## 9. Security Notes

- Exact-email allow rules are intentionally narrower than email-domain rules.
- `login_method` prevents a different configured IdP from satisfying the same email allowlist.
- App-level `allowed_idps` reduces user confusion and avoids accidental IdP selection drift.
- Browser verification should include an unlisted account denial check before the endpoint is considered safe for normal use.
