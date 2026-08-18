# Change Review: PASS

## Decision

PASS. The implementation is scope-compliant, builds locally, activates on Acorn without an Acorn build, and passes direct HTTPS authentication and positions validation. Public recursive DNS now resolves to Acorn and an independent ordinary-hostname fetch reaches the expected bearer-protected response.

## Blocking Findings

None.

## Correctness And Scope

- The diff is limited to the approved Acorn module, age secret registration and ciphertext, tracked adapter source snapshot, and task artifacts. The Cloudflare DNS-only A record is explicitly in scope.
- The adapter is packaged with the existing unstable Rust platform. Its only source delta is the measured `READ_TIMEOUT` increase from 4.5 to 5.8 seconds.
- A fresh SSH clone confirms the tracked `Cargo.toml`, `Cargo.lock`, and `src/main.rs` byte-for-byte match upstream commit `8dcf21f9a2549212bff4b380dc5daf3f5c1236f9` before that derivation patch.
- The service is enabled as a dedicated unprivileged user and binds only `127.0.0.1:8090`; nginx is the sole public listener.
- ACME succeeded, an unauthenticated direct-SNI request returned `401`, and authenticated direct-SNI `/api/accounts` and `/api/positions` requests returned `200` with five live positions.

## Security Lens

Applied because this change introduces an authentication boundary, encrypted identity material, a public TLS proxy, and an inbound bearer requirement.

- The repository contains only the age-encrypted environment file. Targeted plaintext scans found no identity seed, user ID, exclusion ID, or bearer value.
- The 43-character bearer remains derived by the adapter's existing constant-time HMAC verification path; the change does not add a second plaintext token store.
- Systemd hardening prevents privilege escalation, removes capabilities, isolates devices and temporary files, protects the filesystem and home directories, and restricts the adapter to Unix/IPv4/IPv6 socket families.
- Nginx terminates TLS and proxies only to the loopback service. Direct validation confirms the bearer check remains enforced at the application boundary.

No exploitable trust-boundary regression was found.

## Evidence

- `docs/test-report.md` records the local `nix build`, required remote `nixos-rebuild switch`, service state, listener scope, ACME result, authenticated endpoint result, Cloudflare provider confirmation, public DoH resolution, and ordinary-hostname `401` response.
- The local build ran all 10 vendored upstream tests successfully.
- The deployment uses the required `--build-host localhost` remote activation command, so Acorn did not build the closure.

## Non-Blocking Follow-Up

- The upstream authentication and Fund read endpoints occasionally fail transiently. The adapter fails closed with `502`; callers that require stronger availability should retry rather than rely on a single request.
- This local environment's fake-IP resolver still prevents direct ordinary-hostname curl validation. The public DoH and independent-hostname fetch evidence is authoritative for this rollout.
