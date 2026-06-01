# RFC: Gatus Axiom Cloudflare Access

> **Profile**: RFC Heavy (Access / permission boundary)  
> **Status**: Draft  
> **Owners**: agent/user  
> **Created**: 2026-05-17  
> **Last Updated**: 2026-05-17

## Executive Summary

- **Problem**: Gatus currently exposes `status.0xc1.space` from `acorn` through nginx/ACME, while the desired public shape is host-scoped and protected like `opencode-axiom`.
- **Decision**: use `status-axiom.0xc1.space`, run Gatus on `axiom`, route it through `home-axiom` cloudflared to `127.0.0.1:8080`, and protect it with Cloudflare Access matching `opencode-axiom`.
- **Impact**: `acorn` stops owning the public status page; `axiom` owns runtime and tunnel transport.
- **Risk**: Cloudflare Access policy mistakes can overexpose the page; verify through API assertions, not only repo build.
- **Rollback**: remove status ingress and Access/DNS route, disable `axiom` Gatus, restore `acorn` status module if needed.

## Context / Evidence

- Current Gatus deployment: `hosts/acorn/modules/status.nix` with `domain = "status.0xc1.space"`.
- Current axiom tunnel: `hosts/axiom/default.nix` routes `opencode-axiom.0xc1.space` to local opencode on `127.0.0.1:4096`.
- Current Access truth: wiki records `opencode-axiom.0xc1.space` as Google-only Access with exact emails `c1@ntnl.io`, `siyuan.arc@gmail.com`, `froggy2818@gmail.com`.
- User explicitly delegated hostname choice between `status.axiom.0xc1.space` and `status-axiom.0xc1.space`.

## Goals

- Use `status-axiom.0xc1.space` as the public URL.
- Move Gatus host enablement from `acorn` to `axiom` while keeping loopback binding and Prometheus scrape support.
- Add `status-axiom.0xc1.space` to `home-axiom` cloudflared ingress.
- Configure Cloudflare DNS/tunnel route and Access app/policy matching opencode axiom.
- Update docs, Legion evidence, wiki, and Linear with the final public entrypoint.

## Non-goals

- Do not change the `opencode-axiom.0xc1.space` service or Access policy except as a comparison source.
- Do not introduce Terraform or a new Cloudflare IaC framework.
- Do not add alerting or incident workflow.
- Do not run a production `nixos-rebuild switch`.

## Options

### Option A: `status-axiom.0xc1.space` on `axiom` via cloudflared (Chosen)

Pros:

- Matches `opencode-axiom.0xc1.space` service-host naming.
- Keeps tunnel origin local to `axiom` (`127.0.0.1:8080`).
- Uses same Cloudflare Access mental model as opencode.
- Avoids nested `axiom.0xc1.space` subdomain conventions.

Cons:

- Moves Gatus runtime from server-like `acorn` to workstation-like `axiom`.
- Requires Cloudflare control-plane changes.

### Option B: `status.axiom.0xc1.space` on `axiom` via cloudflared

Pros:

- Reads naturally as a host subdomain.

Cons:

- Introduces a new naming hierarchy absent from existing host-specific service routes.
- May require additional wildcard/subdomain reasoning in Cloudflare Access and DNS docs.

### Option C: Keep Gatus on `acorn`, proxy through `axiom` tunnel

Pros:

- Avoids moving Gatus runtime.

Cons:

- `axiom` cloudflared would proxy a remote service instead of local loopback, unlike opencode.
- Adds an extra dependency chain and failure mode.
- Leaves unclear ownership between `acorn` nginx and `axiom` tunnel.

## Decision

Choose Option A.

Implementation should make `status-axiom.0xc1.space` the current public route and remove the old `status.0xc1.space` public route from `acorn`.

## Proposed Design

### Repo Configuration

- Move `hosts/acorn/modules/status.nix` intent into `axiom` host config.
- On `axiom`, enable:
  - `modules.services.prometheus.enable = true`
  - `modules.services.gatus.enable = true`
  - `modules.services.gatus.domain = null` or omitted, because cloudflared handles public ingress.
  - `modules.services.gatus.prometheusScrape.enable = true`
  - Existing initial endpoints, with self-check still `http://127.0.0.1:8080`.
- Update `modules.services.cloudflared.extraConfig.ingress` on `axiom`:
  - Preserve `opencode-axiom.0xc1.space -> http://127.0.0.1:4096`.
  - Add `status-axiom.0xc1.space -> http://127.0.0.1:8080` before the 404 catch-all.
- Remove `./modules/status.nix` import from `hosts/acorn/default.nix`; delete or neutralize `hosts/acorn/modules/status.nix`.

### Cloudflare Route / DNS

Use the existing `home-axiom` tunnel id/name as the route target. Preferred command/API shape:

- `cloudflared tunnel route dns home-axiom status-axiom.0xc1.space`, or equivalent Cloudflare DNS API upsert to point the hostname at the tunnel CNAME.
- Verify the hostname resolves as a tunnel-backed DNS record for `status-axiom.0xc1.space`.

### Cloudflare Access

Create or reconcile exactly one self-hosted Access app for `status-axiom.0xc1.space`:

- type: `self_hosted`
- domain: `status-axiom.0xc1.space`
- allowed IdP: current Google IdP
- auto redirect to identity: true where supported
- session duration: align with opencode (`24h` if existing API state confirms it)

Create or update one allow policy:

- decision: `allow`
- include exact emails: `c1@ntnl.io`, `siyuan.arc@gmail.com`, `froggy2818@gmail.com`
- require Google login method / IdP
- no broad email domain, everyone, group, service token, bypass or non-identity allow policy

If an app/policy already exists for the hostname, reconcile it in place if safe; otherwise document conflict and stop rather than creating ambiguous parallel apps.

## Milestones

- **Milestone 1: Repo config migration**
  - Move Gatus enablement to `axiom`, add cloudflared ingress, remove `acorn` public route, update runbook.
  - Acceptance: targeted Nix eval/build proves `axiom` Gatus and cloudflared shape; `acorn` no longer has the old Gatus vhost.
- **Milestone 2: Cloudflare control-plane**
  - Upsert DNS/tunnel route and Access app/policy.
  - Acceptance: API assertions prove exact app/policy/IdP/allowlist state.
- **Milestone 3: Delivery evidence**
  - Verification, security review, walkthrough, wiki and PR lifecycle.

## Verification

Automated/local:

- `nix build .#nixosConfigurations.axiom.config.system.build.toplevel --no-link`
- targeted eval for:
  - `axiom` `services.gatus.settings.web.address == "127.0.0.1"`
  - `axiom` cloudflared ingress includes `status-axiom.0xc1.space`
  - `axiom` Prometheus scrape config includes `127.0.0.1:8080`
  - `acorn` no longer exposes `status.0xc1.space` nginx vhost
- `git diff --check`
- secret hygiene checks: no plaintext Cloudflare token or duplicate API token secret introduced

Cloudflare API/CLI:

- verify the DNS/tunnel route exists for `status-axiom.0xc1.space`
- verify exactly one Access app for `status-axiom.0xc1.space`
- verify app type/domain/allowed IdP/auto-redirect shape
- verify allow policy exact emails and Google requirement
- verify absence of bypass or broad allow policies

Manual/post-deploy:

- deploy `axiom` and check `systemctl status gatus cloudflared prometheus`
- browser test allowed Google account succeeds
- browser test unlisted Google account fails
- confirm Prometheus can query Gatus metrics

## Rollback

Repo rollback:

- remove `status-axiom` ingress from `axiom` cloudflared
- disable `modules.services.gatus` on `axiom` or remove the host-local status config
- restore `acorn` status import/module if the old public entrypoint is desired again

Cloudflare rollback:

- delete or disable the `status-axiom.0xc1.space` Access app/policy
- delete the `status-axiom.0xc1.space` tunnel DNS route

No data migration is required. Gatus sqlite state can remain on whichever host last ran it or be manually removed after rollback.

## Observability

- Gatus status page and `/metrics` remain the primary observability surface.
- Prometheus scrape job `gatus` should expose `gatus_results_endpoint_success`, `gatus_results_duration_seconds`, `gatus_results_total`, and certificate expiry metrics.
- Cloudflared logs on `axiom` prove tunnel transport; Cloudflare Access audit logs prove auth decisions after deployment.

## Security & Privacy

- Access app/policy is the authentication boundary; cloudflared ingress is only transport.
- The status page must not list private-only dependencies or sensitive hostnames without a separate review.
- Do not commit API tokens or tunnel credential JSON.
- Do not broaden Access rules beyond the exact-email Google allowlist inherited from opencode axiom.

## Open Questions

- Cloudflare API credentials may be unavailable or insufficient; if so, implementation must stop with exact manual steps.
- Interactive browser Access UX validation may remain manual.

## References

- Plan: `.legion/tasks/gatus-axiom-cloudflare-access/plan.md`
- Prior Gatus task: `.legion/tasks/gatus-status-page-blackbox-monitoring/**`
- Prior Access evidence: `.legion/tasks/axiom-charlie-opencode-access-google-oidc/docs/test-report.md`
- Current files: `hosts/axiom/default.nix`, `hosts/acorn/modules/status.nix`, `docs/gatus-status.md`
