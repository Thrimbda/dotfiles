# RFC: Restore 1Ex Portfolio Sampling And Initialize Fund Units

> **Profile**: RFC Heavy (authentication boundary and financial accounting event)
> **Status**: Draft
> **Owners**: user and agent
> **Created**: 2026-08-20
> **Last Updated**: 2026-08-20

## Executive Summary

- **Problem**: The active Acorn adapter closure predates the tracked `redirect_uri` audience fix and returns `502` when 1Exchange reads the source.
- **Decision**: Build the current, already-merged vendor under a fresh package derivation identity from a clean dotfiles worktree, then deploy it. Only after live source and immediate Fund-sample preflight pass, create one owner initial-investment event using that sample's equity and immediately sample again.
- **Why now**: The Fund has positive assets but zero units, so its unit price remains `1` and cannot represent portfolio performance.
- **Impact**: Restores source sampling and establishes personal Fund units without changing credentials, source/Fund binding, or upstream services.
- **Risks**: Authentication audience mismatch, deployment failure, live-value drift, and a non-idempotent accounting event.
- **Rollout**: Change only the Nix package version identity to force a fresh source output, deploy it, verify the running binary and source, preflight a fresh Fund sample, then perform one guarded accounting write and one immediate sample.
- **Rollback**: Before the accounting write, stop on any failed deployment or source validation and retain the prior Acorn generation. After a successful accounting write, do not delete or retry events automatically; record the state and require an explicit accounting-repair decision if the immediate sample fails.

## Background And Goals

The tracked adapter sends its 1Exchange origin as `redirect_uri` during Ed25519 verification. Auth-mini maps the HTTPS host to the `1ex.ntnl.io` audience required by 1Exchange. The active binary lacks that behavior, so the source fails closed with `502`.

The private `My Portfolio` Fund samples the adapter's underlying positions as total assets. It has no investor cash flow, hence zero issued shares and a default unit price of `1`. The goal is to restore the existing source implementation and establish one owner position at the current verified Fund equity.

## Non-goals

- Change auth-mini, 1Exchange, token policy, credentials, or service hardening.
- Change the Custom Account Source URL/header, Fund ID, Fund visibility, Fund target currency, or recursion exclusion.
- Backfill or rewrite historical performance.
- Apply taxation, settlement, external investor subscriptions, or any automatic accounting repair.

## Constraints

- Build and deploy only from Axiom using exactly:

```sh
nixos-rebuild switch --flake .#acorn --target-host c1@8.159.128.125 --build-host localhost --sudo --ask-sudo-password --use-substitutes -L
```

- Never build or evaluate the system closure on Acorn.
- Keep all private key, password, bearer, and decrypted environment material out of logs, documents, Git, and command output.
- Run every preflight and the one accounting mutation under a newly minted short-lived `1ex.ntnl.io` audience session.

## Proposed Design

### Deployment Boundary

Deploy the existing vendor source unchanged from a clean worktree at `origin/master`. Axiom has an invalid local-store state: the prior adapter output is registered and live but absent on disk, so the daemon refuses both repair and safe deregistration. Change only the Nix package `version` suffix to force a new derivation output path. The Nix package then recompiles the same vendor source and restarts `oneex-portfolio-adapter.service`. This is a deployment reconciliation, not an adapter source-code change.

Validate the rollout in this order:

1. Confirm systemd is active, its executable path differs from the missing prior output, and it contains the `redirect_uri` literal.
2. Authenticate to 1Exchange with a short-lived device session whose verify request includes `redirect_uri=https://1ex.ntnl.io`.
3. Confirm the registered source's account positions return HTTP `200`, expected non-empty positions, finite valuations, and no Fund self-row.
4. Immediately sample `My Portfolio`; require positive USD equity, no unpriced positions, and a position count consistent with the source.

Any failure before step 4 stops the task before accounting changes.

### Fund Initialization Boundary

Use the successful immediate-sample equity `E` as the only baseline. Immediately before mutation, re-read the Fund statement and require:

- exactly zero active investors;
- exactly zero total shares;
- positive finite `E`;
- source positions and the pre-write sample still healthy.

Create one owner investor through `POST /api/fund-investors` with the authenticated owner ID, current RFC 3339 time, `initial_amount=E`, and a plain initialization comment. Optional tax/referrer fields remain absent because no tax or referral policy is in scope.

The endpoint appends the owner profile and positive cash-flow event atomically. It is intentionally invoked once only. Then immediately call `POST /api/funds/sample` again. The sample replaces the interim reducer value with the actual current trading equity, so the unit price becomes `total_assets / total_shares` instead of the zero-share fallback of `1`.

## Alternatives Considered

### Option A: Redeploy the current vendor, then initialize once

- **Pros**: Uses the already-reviewed audience fix, retains fail-closed behavior, proves source health before accounting, and keeps the financial baseline tied to a fresh observable value.
- **Cons**: Requires a production switch and a guarded accounting operation.

### Option D: Force a fresh Nix package derivation from the same vendor source, then use Option A

- **Pros**: Removes the missing local-store output from the new closure without faking a store path, deleting a live path, or changing adapter behavior. The normal Axiom build verifies and produces the new output.
- **Cons**: Changes package derivation identity and requires renewed RFC review before deployment.

### Option B: Write owner units while the source remains `502`

- **Pros**: Avoids deployment work.
- **Cons**: Cannot safely re-sample after the event. The temporary doubled accounting state could persist, and the source defect remains.

### Option C: Loosen 1Exchange audience validation or change auth-mini defaults

- **Pros**: Could make the old adapter token acceptable.
- **Cons**: Broadens or changes an authentication boundary and affects other services. It is larger, less contained, and unnecessary because the adapter already has the correct request behavior.

### Decision

Choose Option D followed by Option A. It is the smallest safe response to Axiom's invalid store state: it retains the intended audience boundary, builds the current vendor from source into a new output, validates the live source before financial mutation, and has a clear pre-write rollback boundary.

## Rollout And Rollback

### Rollout

1. Change only the adapter package version suffix, then build and activate the current clean dotfiles worktree from Axiom with the prescribed command.
2. Verify active binary, systemd health, authenticated source positions, and a fresh immediate Fund sample.
3. Read Fund statement preconditions and create the single owner baseline event.
4. Immediately sample again and verify positive issued units, fully priced valuation, and a non-fallback unit price calculation.

### Rollback

- If deployment or source verification fails: stop before the accounting event. The previous Acorn NixOS generation remains the rollback point; report the failure rather than attempting alternate auth behavior.
- If the pre-write immediate sample fails: stop before the accounting event.
- If the post-write immediate sample fails: do not retry, delete, or disable objects automatically. Preserve evidence, report the event index and API status without secrets, and request an explicit accounting-repair decision.

## Observability And Security

- Use systemd active state, fresh executable store path plus binary literal check, adapter `positions` status, source position count, Fund sample diagnostics, and Fund statement totals as evidence.
- Do not log payloads that contain seeds, bearer values, opaque headers, full session tokens, or decrypted environment content.
- A mismatched audience remains fail-closed. No fallback audience, static access token, or bypass of 1Exchange authorization is introduced.
- The source remains loopback-only behind its existing nginx/TLS boundary and carries no new management endpoint.

## Testing Strategy

- Nix build and activation through the prescribed Axiom-to-Acorn command, requiring a fresh adapter output path rather than the missing old one.
- Runtime check that the active executable includes `redirect_uri`.
- Authenticated 1Exchange source read with the intended audience.
- Immediate pre-write and post-write Fund samples with `unpriced_positions=0`.
- Fund statement check for exactly one owner investor, positive shares, and a unit price equal to total assets divided by total shares within live-snapshot tolerance.
- Search changed artifacts for plaintext secret or bearer exposure.

## Milestones

1. **Deploy current adapter**
   - Activate the tracked vendor on Acorn.
   - Acceptance: active binary contains `redirect_uri`; source positions are healthy.
   - Rollback impact: no Fund accounting change yet.
2. **Initialize owner units**
   - Use one immediate sample as the baseline, append exactly one owner event, and sample again.
   - Acceptance: Fund has positive shares and a derived unit price.
   - Rollback impact: post-write failures require an explicit accounting-repair decision.
3. **Closeout**
   - Produce verification, review, walkthrough, wiki, and PR evidence.
   - Acceptance: no unresolved security, source, or accounting blocker remains.

## Open Questions

- None blocking. The live deployment and immediate-sample checks are explicit gates, not assumptions.

## References

- Contract: `../plan.md`
- Research: `research.md`
- Adapter module: `hosts/acorn/modules/oneex-portfolio-adapter.nix`
- Adapter source: `packages/oneex-portfolio-adapter/vendor/src/main.rs`
- Previous registration evidence: `.legion/tasks/register-oneex-portfolio-fund/docs/test-report.md`
