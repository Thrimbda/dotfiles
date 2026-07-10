# Change Review

## Result: PASS

## Findings

No blocking findings.

## Security Lens

Security review was applied because the change handles an SMTP credential and auth email delivery.

- **Secret leakage:** No Resend-key-shaped plaintext was found in the reviewed text files or diffs. The key is absent from Nix values, service arguments, logs, and task evidence. The encrypted artifact was inspected only as metadata: it is a 249-byte regular file, staged as a normal Git blob; its contents were not read or decrypted during review.
- **Recipients and runtime permissions:** `auth-mini-resend-api-key.age` has only the Acorn SSH recipient in `secrets.nix`. Agenix evaluates the runtime file as `auth-mini:auth-mini` with mode `0400`, limiting access to the service principal that already owns the SQLite database containing the configured SMTP credential.
- **Credential handling:** Evidence says the key was streamed over stdin to an authenticated loopback admin API client and was not placed in argv, output, or logs. The temporary admin session was logged out.
- **Retained age secret:** Retaining the Acorn-only age secret is acceptable for this explicitly lightweight task. It supports recovery and rotation without expanding access beyond the principal already trusted with the live SMTP credential. It does create a second protected copy, but not a new trust boundary.
- **One-time API configuration:** The non-declarative admin API update is acceptable within the explicit scope because auth-mini persists SMTP state in SQLite and has no startup SMTP environment interface. Live read-back and an actual OTP request confirm the intended state without exposing the password.

## Scope and Correctness

- The repository change is limited to the task records, one encrypted secret, its Acorn recipient declaration, and an auth-mini-owned agenix declaration. No gateway, user, session, issuer, RP ID, branding, or Vaultwarden configuration changed.
- The Acorn toplevel build and `git diff --check` passed. Focused evaluated output confirms the expected secret path, owner, group, and mode.
- Live evidence confirms `smtp.resend.com:465`, username `resend`, implicit TLS, sender `auth@0xc1.space`, successful provider reachability, and `POST /email/start` returning `200` for the existing admin recipient.

## Residual Risks

- SMTP state remains in application-owned SQLite and is not reconciled from the retained age secret. Database replacement, disaster recovery, or key rotation requires another authenticated admin API update.
- The repository declaration has not yet been switched on Acorn. After merge and switch, verify `/run/agenix/auth-mini-resend-api-key` is `auth-mini:auth-mini` mode `0400` as already identified in the test report.
- Delivery can later fail if Resend domain verification, account policy, recipient policy, or network reachability changes; the successful live OTP proves current behavior only.
