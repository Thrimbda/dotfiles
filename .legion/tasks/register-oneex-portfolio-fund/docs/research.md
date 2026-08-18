# Registration Preflight Research

## Current State

- The deployed adapter's direct discovery and positions path is live, authenticated, and returns five positions.
- A short-lived Ed25519 session minted from the deployed runtime identity matches the configured 1Ex user.
- `GET /api/custom-account-sources` returns zero owned sources.
- `GET /api/funds` returns eight readable Funds; none is named `My Portfolio`.
- The encrypted environment's existing `EXCLUDED_FUND_ID` matches zero current Fund IDs.

## Protocol Facts

- A Custom Account Source is created through `POST /api/custom-account-sources` with `name`, public HTTPS `base_url`, optional `auth_header`, and `enabled`.
- An enabled source contributes its `/api/accounts` result to unified `GET /api/accounts`. Its `auth_header` is never returned after creation.
- A Trading Fund is created or updated through `POST /api/funds` with an owned stable ID, `trading_account_id`, privacy/subscription flags, `USD` target currency, and `enabled` state. Immediate sampling is `POST /api/funds/sample?fund_id=<id>`.
- The adapter filters any upstream Fund whose ID equals `EXCLUDED_FUND_ID` before mapping positions, regardless of its viewer share.

## Authenticated Mutation Path

Acorn lacks OpenSSL on its system PATH, but its active curl closure already contains a Nix-store OpenSSL binary. That binary successfully derives a 43-character Ed25519 public key and an 86-character unpadded base64url signature from a test seed. The one-time operator flow uses it only on Acorn:

1. Root sources the existing age-rendered environment.
2. The raw seed, challenge, short-lived user token, and adapter Bearer stay in process memory or root-owned `0600` files in `/run`.
3. The files are deleted by a shell `trap` on every exit path.
4. The operator calls only the required auth, source, Fund, sample, and logout endpoints; no token is printed or committed.

The system `base64` command wraps long output by default. The signing flow must use `base64 -w 0`; otherwise the 64-byte signature contains an embedded newline and the auth JSON is invalid.

## R3: Initial Sample Residual

**Observation:** The target Fund was created private/USD, but the initial sample produced no NAV event and the failure cleanup left the Fund disabled.

**Explained:** The source itself is enabled and unified discovery returns the expected five stable position IDs. The initial operation did not modify any pre-existing Fund.

**Residual:** The exact sample failure status was not captured. Candidate explanations are a transient upstream `502`, an immediate-sample requirement that the Fund be enabled, or a post-sample assertion failure.

**Evidence boundary:** Fund configuration and empty NAV are post-attempt facts. The original error body is unavailable, so it cannot be treated as evidence.

**Expansion:** Issue exactly one non-retried sample while the Fund remains disabled and capture only its HTTP status plus non-secret response shape. If it succeeds, validate the NAV and enable the Fund. If it rejects disabled state, enable once, sample once, and disable again on failure. If it returns an upstream failure, retain the disabled Fund and stop with the status recorded.

**Closure:** The disabled-state probe returned `200` with USD, five positions, no unpriced rows, and positive equity. The Fund was then enabled and its final configuration plus NAV were read back successfully. The original failure status remains unavailable because the first command did not retain its error body; this is a bounded historical gap, not an active correctness residual.
