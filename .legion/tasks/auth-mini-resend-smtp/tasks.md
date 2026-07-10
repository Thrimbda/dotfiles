# Tasks

- [x] Materialize task contract | Acceptance: goal, scope, constraints, risks, non-goals, and live acceptance are explicit.
- [x] Encrypt Resend key | Acceptance: Acorn-decryptable `.age` file matches source without plaintext output.
- [x] Declare secret and configure SMTP | Acceptance: Acorn owns the age secret and auth-mini receives Resend config through the admin API.
- [x] Verify change | Acceptance: test report records build, secret-hygiene, and live SMTP evidence.
- [x] Review change | Acceptance: readiness/security review records PASS or actionable blockers.
- [x] Produce walkthrough | Acceptance: reviewer-facing walkthrough and PR body summarize the change.
- [x] Write wiki summary | Acceptance: durable secret-handling and operational state are recorded.
- [ ] Complete PR lifecycle and live smoke | Acceptance: PR terminal state, Acorn switch/OTP smoke, cleanup, and main refresh are handled.
