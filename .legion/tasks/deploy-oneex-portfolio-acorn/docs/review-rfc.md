# RFC Review: PASS

## Decision

PASS. The design is implementable, verifiable, and rollbackable within the approved scope.

## Findings

- The pinned source snapshot, systemd ownership model, agenix environment file, loopback bind, nginx/ACME hostname, and exact remote deployment command are explicit.
- The existing HMAC-derived bearer is 43 base64url characters and preserves the adapter's constant-time authentication path without adding a second token mechanism.
- The `5.8s` read budget is supported by live local measurements and still leaves the cumulative phase budget below ten seconds.
- Nix source and Cargo vendor hashes remain implementation inputs. They will be generated and verified by the local build before any remote switch.

## Non-blocking Follow-up

Before creating the self-referential private Fund, replace the no-op exclusion UUID in the encrypted environment with that Fund's actual ID.

## Re-review

PASS. Replacing the inaccessible private-source fetch and pure-flake-invisible submodule with a pinned tracked snapshot removes a build blocker. It does not expand runtime privileges, secret exposure, network surface, or rollback scope.

## DNS Re-review

PASS. The missing DNS-only A record is a blocking external dependency for a public hostname, not a service-design change. The updated RFC makes the target, idempotent update rule, credential boundary, authoritative verification source, and retirement rollback explicit.

## Local Auth Validation

REJECTED. Although local auth-mini accepts the registered public-key challenge, the resulting token is rejected by 1Ex and positions fail immediately. The environment override was removed; the default `https://auth.ntnl.io` path remains the approved design.

## Final Design Decision

PASS. The rejected loopback alternative is explicitly removed from the deployed environment. The original externally accepted issuer, loopback adapter listener, nginx TLS boundary, age secret handling, DNS-only record, and rollback path remain coherent and verifiable.
