# Axiom and Charlie Opencode Cloudflare Access Google OIDC

## Task Contract

### Name

Axiom and Charlie opencode Cloudflare Access Google OIDC

### Task ID

`axiom-charlie-opencode-access-google-oidc`

### Goal

Protect the existing `opencode` Cloudflare Tunnel hostnames for `axiom` and `charlie` with Cloudflare Access, using Google OIDC as the identity source and allowing only `c1@ntnl.io` and `siyuan.arc@gmail.com`. Store the Cloudflare API credential needed for this operation as an age-encrypted repository config/ops secret without committing plaintext.

### Problem

`axiom` now has a loopback-only `opencode-server` and a Cloudflare Tunnel ingress for `opencode-axiom.0xc1.space`, but prior evidence records Cloudflare Access as an external follow-up. `charlie` already has a similar opencode tunnel and prior Access automation, but its allow policy must be brought in line with the same two Google identities. Without an enforced Access layer, a working tunnel hostname can be mistaken for a safe public entry point even though cloudflared ingress alone does not authenticate users.

### Acceptance

- `opencode-axiom.0xc1.space` has a Cloudflare Access self-hosted application or equivalent existing app bound to the hostname.
- `opencode-charlie.0xc1.space` has a Cloudflare Access self-hosted application or equivalent existing app bound to the hostname.
- Both applications require Google OIDC login and allow only `c1@ntnl.io` and `siyuan.arc@gmail.com` unless Cloudflare account state forces a documented blocker.
- The Cloudflare API credential used for the update is stored as an age-encrypted repository config/ops secret, with no plaintext token committed.
- The Cloudflare-side change is verified through API/CLI evidence where credentials are available; if live verification is impossible, the blocker and exact manual steps are recorded.
- Repository documentation and Legion evidence are updated so future operators do not treat cloudflared ingress as sufficient authentication.

### Assumptions

- The Cloudflare zone for `0xc1.space` and the Zero Trust account are reachable from this environment via existing CLI login, API token, or user-provided credentials.
- Google OIDC is either already configured as a Cloudflare Access identity provider or can be selected/created without committing any client secret or token to the repository.
- The target hostnames are `opencode-axiom.0xc1.space` and `opencode-charlie.0xc1.space`.
- `c1@ntnl.io` and `siyuan.arc@gmail.com` are the only identities to allow for this task.
- Existing tunnel connector configuration for axiom and charlie remains valid and should not be replaced unless inspection proves it is inconsistent with the Access goal.
- The repository's existing global public age recipient in `config/secrets/secrets.nix` is acceptable for encrypting the ops credential unless implementation discovers a more specific approved recipient.

### Constraints

- Follow Legion workflow and use a PR-backed worktree envelope before repository modification beyond task setup.
- Do not print or commit plaintext Cloudflare API tokens, OIDC client secrets, tunnel credential JSON, or other secret material.
- Do not register the Cloudflare API token in the globally deployed agenix secret map unless explicitly re-approved; a repo config/ops age file is acceptable, broad host deployment is not.
- Keep `opencode-server` loopback-only; do not change either service to listen on `0.0.0.0` or LAN interfaces.
- Keep Cloudflare Access configuration least-privilege: only the two requested identities, no broad domain allow unless explicitly re-approved.
- Prefer minimal repository changes: task evidence and targeted docs/notes unless implementation discovery shows a durable config artifact is needed.

### Risks

- **Risk level: High.** This task controls public access to remote opencode capabilities; a policy or identity-provider mistake can expose a sensitive service.
- Cloudflare Access API state may differ from prior task evidence, requiring reconciliation instead of blind creation.
- Google OIDC provider setup may require client secrets unavailable to this environment; that would become a documented external blocker.
- Existing charlie Access policy may already allow `c1@ntnl.io`; adding `siyuan.arc@gmail.com` must not accidentally broaden access beyond the requested identities.
- Putting an account-level Cloudflare API token into a globally deployed agenix map would unnecessarily distribute high-privilege credentials; implementation must keep the age secret ops-scoped unless the user explicitly accepts host deployment.
- Live browser verification may require interactive Google login and may not be fully automatable here.

### Scope

- Inspect existing axiom and charlie opencode tunnel/Access evidence.
- Discover Cloudflare Zero Trust Access applications, policies, and identity providers for the two hostnames.
- Create or update Access applications/policies so the two hostnames require Google OIDC and allow only `c1@ntnl.io` plus `siyuan.arc@gmail.com`, where credentials permit.
- Encrypt the provided Cloudflare API environment file into a repository config/ops age secret and remove any plaintext staging file from the worktree.
- Update task evidence and any directly relevant repository docs that currently present the Access state or required manual checks.
- Verify with Cloudflare API/CLI and available local checks.

### Non-Goals

- Do not redesign the opencode service, tunnel IDs, DNS routes, or cloudflared connector module unless they block Access enforcement.
- Do not introduce Terraform or a new Cloudflare IaC framework in this task.
- Do not deploy the Cloudflare API token to every NixOS/Darwin host as part of normal system activation.
- Do not add a second application-layer authentication scheme for opencode.
- Do not deploy NixOS/Darwin system changes to physical hosts unless separately requested.
- Do not broaden access to an email domain, Google group, or everyone in the Zero Trust organization.

### Design Summary

- Treat Cloudflare Access as the authentication boundary and cloudflared ingress as transport only.
- Reconcile existing state instead of replacing it: keep app IDs and policies when safe, update include rules and identity provider constraints in place where possible.
- Use a single shared access intent for both hostnames: Google OIDC plus exact-email allowlist for `c1@ntnl.io` and `siyuan.arc@gmail.com`.
- Store the API credential as an age-encrypted ops secret under repository config space, but keep it out of host-wide agenix deployment by default.
- Record any impossible live action as an explicit blocker with the exact Cloudflare console/API steps, rather than marking the endpoint protected by assertion.

### Phases

1. **Design gate** - Produce and review an RFC for Cloudflare Access app/policy reconciliation, Google OIDC identity-provider handling, rollback, and verification.
2. **Implementation** - Apply the bounded Cloudflare-side change and update directly relevant docs/evidence without touching secrets.
3. **Verification** - Prove Access app, policy, identity provider, and allowlist state through API/CLI evidence where possible.
4. **Review and delivery** - Run readiness/security review, produce walkthrough/PR body, update wiki, and complete PR lifecycle.

---

*Created: 2026-05-11*
