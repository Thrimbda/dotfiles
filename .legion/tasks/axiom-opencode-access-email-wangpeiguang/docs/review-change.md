# Review Change: Axiom Opencode Access Email Allowlist

## Verdict

PASS.

Security lens applied because the task changes identity/access policy and uses a Cloudflare API token.

## Findings

- No blocking findings.

## Scope And Security Review

- Scope compliance: PASS. The change updates `opencode-axiom.0xc1.space` Access allowlist state, repo docs, task evidence, and related wiki truth. It does not modify `opencode-charlie`, `status-axiom` live policy, cloudflared ingress, DNS, opencode runtime, tunnel credentials, or API token storage.
- Least privilege: PASS. The new access grant is one exact email rule. No domain, group, everyone, bypass, service-token, or non-identity allow was added.
- Identity provider boundary: PASS. API readback confirms the app remains restricted to Google IdP `399adc69-d770-4685-8acf-cdea3acca230`, and the allow policy still requires that Google login method.
- Secret handling: PASS. The API token was decrypted in-memory from `hosts/charlie/secrets/cloudflare-api-token.age` with `~/.ssh/id_ed25519`; no token value, tunnel secret, private key, or account id was printed or committed.
- Documentation accuracy: PASS. Repo/wiki now record the verified axiom allowlist and explicitly avoid implying `status-axiom` automatically inherits opencode allowlist changes.

## Verification Review

- `docs/test-report.md` includes repo text assertions for axiom and charlie allowlists.
- Cloudflare API evidence records policy update success and final assertions: one app, correct app shape, one exact-email allow policy, and zero unsafe allow/bypass policies.
- `git diff --check` passed.
- Interactive browser login smoke remains manual, which is acceptable because API assertions prove the Access app/policy shape.

## Residual Risks

- Browser-session smoke with `wangpeiguangwpg@gmail.com` was not run in this environment. The API state is sufficient for merge/readiness, but manual browser verification is still recommended.
- The pre-existing Cloudflare API token rotation follow-up remains outside this task.

## Conclusion

The repo diff and live Cloudflare Access state are ready for reviewer handoff.
