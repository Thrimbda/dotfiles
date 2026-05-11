# Review RFC: axiom/charlie opencode Cloudflare Access Google OIDC

## Verdict

PASS — implementation can begin.

## Blocking Findings

None.

## Review Evidence

- The updated contract adds a requirement to store the Cloudflare API credential as an age-encrypted repository config/ops secret without committing plaintext (`plan.md:15`, `plan.md:26`, `plan.md:62`). The RFC now includes this in the final intended state and implementation plan (`docs/rfc.md:31-32`, `docs/rfc.md:82-95`).
- The credential design remains safe enough for implementation because it explicitly avoids plaintext commits, uses an approved age recipient, deletes plaintext staging after use, and does not register the token into the globally deployed agenix secret map by default (`docs/rfc.md:88-95`, `docs/rfc.md:141-142`). This addresses the plan constraint against broad host deployment (`plan.md:42-43`, `plan.md:54`, `plan.md:70`).
- The Access reconciliation design remains implementable: it defines credential-safe discovery, Google IdP selection, exact app lookup/create/update behavior, and exact allow-policy reconciliation for both hostnames (`docs/rfc.md:82-123`).
- The design remains verifiable: it requires API/CLI evidence for IdP, app, policy, login-method, and broad-policy absence, plus repository checks that the age file exists, plaintext staging is absent from git status, and the age file is not registered for global deployment (`docs/rfc.md:131-150`).
- The design remains rollbackable: it captures sanitized pre-change app/policy state and includes rollback for app/policy mutations plus optional removal of the age credential and token revocation documentation (`docs/rfc.md:152-167`).
