## Summary

- add `wangpeiguangwpg@gmail.com` to the verified Cloudflare Access allowlist for `opencode-axiom.0xc1.space`
- update repo docs/wiki to reflect the current Google-only exact-email Access policy
- clarify that `status-axiom` does not automatically inherit future opencode allowlist changes

## Verification

- PASS: repo text assertions for axiom and charlie allowlists
- PASS: Cloudflare API update/readback for policy `5593f601-c883-4bb8-8e76-1ba02b6c7b4a`
- PASS: final assertions `appCount=1`, `appShapeOk=true`, `exactAllowPolicyCount=1`, `unsafeAllowOrBypassCount=0`
- PASS: `git diff --check`
- PASS: `docs/review-change.md`

## Notes

- Browser smoke for `wangpeiguangwpg@gmail.com` is still recommended.
- No plaintext token, tunnel secret, private key, or account id is committed.
