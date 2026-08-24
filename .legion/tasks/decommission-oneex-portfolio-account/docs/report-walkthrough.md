# Walkthrough: 1Ex Portfolio Adapter Undeployment

> **Mode:** `implementation`
> **Result:** PASS

## Delivered

PR [#203](https://github.com/Thrimbda/dotfiles/pull/203) merged as `df26dce7f6b0652172cf5d604527f18d73cd76a5`. Its complete production change is one deletion in `hosts/acorn/default.nix`:

```diff
-    ./modules/oneex-portfolio-adapter.nix
```

The mandated Axiom-to-Acorn switch completed build/realization, transfer, and activation successfully from Axiom. Both active-system links resolve to `/nix/store/aasj72hy0vdl7sbgdgfib54x4bnhgggc-nixos-system-acorn-26.05.7813.0dd31db7e6db`, whose configuration revision is the merged commit; no Nix build or evaluation ran on Acorn. See `test-report.md` and `review-change.md`.

## Final Evidence

- **Unit:** the adapter service and its ACME service/timer are `not-found`, `inactive`, and `dead`.
- **Process/port:** no adapter process or TCP `8090` listener exists.
- **Vhost:** the active nginx configuration contains neither `1ex-portfolio.0xc1.wang` nor `8090`; verified TLS rejects the hostname, while the unauthenticated diagnostic reaches only the default `404`.
- **Health:** all nine checked unrelated services are active, and no failed unit is reported. See `test-report.md`.

## Intentional Boundaries

The runtime age secret remains without being read. Its ciphertext/declaration, the dormant adapter module, and the package snapshot also remain intentionally. No browser state, 1Exchange or other external account state, auth-mini state, credential, or secret was mutated.
