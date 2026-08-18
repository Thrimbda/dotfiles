# RFC: Deploy the 1Ex Portfolio Adapter on Acorn

## Context

The adapter has been validated locally against the real auth-mini and 1Ex endpoints. A real authenticated Fund read takes about 5.2 to 5.4 seconds, so the upstream `4.5s` read budget returns a false `502`; `5.8s` succeeds while the sum of all phase budgets remains below ten seconds.

Acorn already provides Cloudflare DNS-01 ACME, nginx, agenix, and an auth-mini deployment. The approved public name is `1ex-portfolio.0xc1.wang`.

Cloudflare public DNS initially returns `NXDOMAIN` for that name. DNS-01 issuance creates only `_acme-challenge` records, so a separate DNS-only `A` record is required for the public hostname to reach Acorn.

## Decision

Deploy a dedicated, non-root `oneex-portfolio-adapter` systemd service that listens only on `127.0.0.1`. nginx terminates TLS for `1ex-portfolio.0xc1.wang` and reverse-proxies requests without replacing the caller's `Authorization` header.

The service environment is one Acorn-only agenix secret containing the existing registered Ed25519 seed, the JWT-backed user ID, a random no-op `EXCLUDED_FUND_ID`, and the loopback bind address. The adapter's existing HMAC-SHA-256 inbound bearer is derived from that seed. Its unpadded base64url representation is 43 characters, satisfies the requested 32-character minimum, and is not committed in plaintext.

Package source is a Git-tracked snapshot exported from GitHub revision `8dcf21f9a2549212bff4b380dc5daf3f5c1236f9`. The repository is private, so Nix's unauthenticated GitHub archive fetcher cannot retrieve it. A Git submodule is also insufficient because pure flake evaluation for the required `--flake .#acorn` command excludes its working-tree contents. The snapshot makes the exact source available to a pure local build without an absolute workstation path. The Nix derivation uses the repository's unstable Rust platform, which evaluates to Rust 1.97 and satisfies the source's Rust 1.96 requirement. A narrow derivation patch changes only `READ_TIMEOUT` from `4_500` to `5_800` milliseconds; it preserves the upstream source and the locally validated behavior without changing the upstream repository.

## Alternatives

### Reference the local adapter checkout

Rejected. An absolute local source path would make Acorn configuration evaluation depend on this workstation and is not reproducible for future operators.

### Vendor the pinned source snapshot

Selected. Nix cannot retrieve the private repository or include a submodule under the required pure flake invocation. The snapshot is explicitly versioned by the package version and source revision, so updates require a deliberate source refresh rather than an implicit local dependency.

### Fetch the GitHub archive directly in the Nix derivation

Rejected. The source repository is private and the unauthenticated GitHub archive endpoint returns `404` to Nix.

### Use a Git submodule as package source

Rejected. Nix's pure flake source filter sees the Gitlink but excludes the checked-out submodule files when evaluating `--flake .#acorn`, making the package non-buildable.

### Add a separate configurable static bearer implementation

Rejected. The current adapter already has a 256-bit derived bearer and constant-time verification. Adding a second authentication path would expand the code surface without improving this deployment.

### Keep the 4.5-second read budget

Rejected. Real authenticated Fund reads exceed it and cause a deterministic false `502` under normal live latency.

### Use Acorn local auth-mini

Rejected. The local service accepts the registered public-key challenge, but 1Ex immediately rejects the locally minted access token. The adapter must retain its default `https://auth.ntnl.io` issuer/signing context for a usable 1Ex audience token.

## Security Boundaries

- The adapter process has a dedicated system user, an agenix environment file owned `0400`, no writable state directory, no home access, a private temporary directory, `NoNewPrivileges`, an empty capability set, and a strict system filesystem view.
- Only nginx listens publicly. The adapter binds to loopback and continues to reject requests without the bearer.
- The service secret, Ed25519 seed, access tokens, and derived bearer never enter tracked plaintext Nix files, service logs, or validation output.
- A random placeholder exclusion ID is intentionally a no-op because no current Fund exactly matches the adapter account. Before creating the self-referential private Fund, the operator must replace it with that Fund ID.

## Public DNS

Create or update the Cloudflare DNS-only record `1ex-portfolio.0xc1.wang A 8.159.128.125` with automatic TTL and `proxied=false`. Query the existing record first, create it only when absent, and update it only if it does not match the intended A record. The existing encrypted `CF_DNS_API_TOKEN` is decrypted only in local process memory; neither the token nor response payloads beyond record metadata are logged.

Cloudflare DoH is the authoritative validation path because the local resolver uses fake-IP addresses in `198.18.0.0/15`. Direct SNI requests to Acorn are a separate origin validation path.

## Rollout and Validation

1. Upsert the DNS-only Cloudflare A record using the existing encrypted token.
2. Build the Acorn configuration on the local build host.
3. Apply only with:

   ```sh
   nixos-rebuild switch --flake .#acorn --target-host c1@8.159.128.125 --build-host localhost --sudo --ask-sudo-password --use-substitutes -L
   ```

4. Check `oneex-portfolio-adapter.service`, nginx, certificate issuance, and authenticated `/api/accounts` plus `/api/positions` through the public hostname.
5. Confirm the returned valuation is live data, not a false zero or partial response.

If activation or validation fails, select the previous NixOS generation or run `nixos-rebuild switch --rollback` on Acorn. The service and vhost disappear with the rolled-back generation; no mutable application state requires migration. Remove the A record if the endpoint is retired rather than restored.

## Non-goals

- Change 1Ex portfolio mapping, pricing, Fund exclusion semantics, or auth-mini behavior.
- Alter unrelated Acorn services.
- Build or evaluate the system closure on Acorn.
