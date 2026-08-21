# RFC Review

## Decision

PASS.

## Blocking Findings

None.

## Review Evidence

- The RFC correctly separates the stale active closure from the already-correct tracked vendor. It does not propose weakening 1Exchange audience validation or changing auth-mini.
- The deployment command is constrained to an Axiom build with Acorn as the target host, so it does not violate the no-build-on-Acorn rule.
- The source health check and a fresh immediate Fund sample are hard preconditions for the accounting mutation.
- The baseline is defined by the same-run sample rather than an earlier live display, which prevents stale-value unit issuance.
- The design recognizes that the initial-investment endpoint is non-idempotent and explicitly prohibits automatic retry, deletion, or compensation after a post-write failure.
- Rollback is feasible before the accounting event through the prior Acorn generation. After the event, the required stop-and-escalate behavior preserves accounting auditability.

## Non-blocking Notes

- A binary string check is only deployment evidence; the required source position read remains the behavioral acceptance test.
- The post-write unit price may differ slightly from `1` if the live account changes between the baseline and immediate follow-up sample. The required invariant is `unit_price = total_assets / total_shares`, not an exact displayed constant.

## Implementation Gate

The design is ready for the deployment and guarded Fund-initialization implementation phase.

## Re-review: Fresh Derivation Identity

PASS.

- Evidence now shows that the missing adapter output is a live, registered Axiom store path. The daemon does not support repair, and normal deletion refuses the live path. The design must not force-delete or fabricate it.
- The package version suffix changes only the Nix derivation/output identity. `src`, `Cargo.lock`, adapter runtime behavior, source authentication header, Fund binding, and all secret material remain unchanged.
- The new system closure will refer to the newly built adapter output rather than the missing old output. The prescribed Axiom build remains the sole mechanism that can create and activate it.
- The previous Acorn generation remains the rollback boundary until the accounting event. No Fund mutation is permitted until the fresh output passes live source and immediate-sample verification.
- No new authentication bypass, credential, API contract, data migration, or accounting behavior is introduced.
