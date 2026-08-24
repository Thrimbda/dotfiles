# Change Review: Minimal 1Ex Portfolio Adapter Undeployment

## Verdict

**FINAL SECURITY REVIEW: PASS.**
**Blockers: None.**

## Findings

1. PR #203 merged as `df26dce7f6b0652172cf5d604527f18d73cd76a5`; Acorn runs `/nix/store/aasj72hy0vdl7sbgdgfib54x4bnhgggc-nixos-system-acorn-26.05.7813.0dd31db7e6db`, whose metadata names that revision.
2. The complete production scope is one deletion from `hosts/acorn/default.nix`: `./modules/oneex-portfolio-adapter.nix`. The dormant module, package, secrets, agenix module, and other production files are unchanged.
3. Runtime checks pass: adapter and ACME units are not found; no process or TCP `8090` listener exists; active nginx has no adapter hostname/proxy; verified TLS rejects the hostname and the credential-free fallback returns `404`.
4. All nine checked services are active and no failed unit exists. The retained age secret passed an existence-only check without content or target disclosure.
5. Deployment/build originated on Axiom, with no Acorn-local Nix build. No external account, browser, auth API, credential, or secret mutation occurred.

## Residual Risks

- The runtime secret, ciphertext/declaration, dormant module/package, DNS, old generations/store paths, and external 1Exchange/auth-mini metadata remain by design.
- Re-importing the module or booting an older generation could restore the service; external account retirement and credential revocation were out of scope.

The retained credential creates no unresolved issue within the reviewed service-only boundary because its consumer, process, listener, and public vhost are absent.

References: `test-report.md`, `rfc.md`, `review-rfc.md`, `research.md`, `../plan.md`, `../log.md`.
