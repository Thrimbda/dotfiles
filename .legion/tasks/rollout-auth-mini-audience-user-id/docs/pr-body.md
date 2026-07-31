# Close audience gateway rollout

## Summary

Close the production rollout for audience-bound auth-mini gateways:

- gateway package pinned to upstream `e1ea3e77fc39612b7418a3a44db5e2cc2b8618d4`;
- Axiom and Acorn encrypted envs migrated to the supplied exact user ID without exposing it in repository files;
- Axiom proxy gateways set `UPSTREAM_PROTOCOL=http1`;
- PR #157 merged the package/env migration;
- PR #158 merged the cleartext protocol fix;
- Axiom and Acorn live services are active and return correct auth-mini login redirects.

## Evidence

See `.legion/tasks/rollout-auth-mini-audience-user-id/docs/test-report.md`, `docs/review-change.md`, and `docs/report-walkthrough.md`.

## Remaining

The user performs the credential-bearing browser login smoke. Automation did not modify production auth-mini data or use real credentials.
