## Summary

- **Mode:** `implementation`
- PR [#203](https://github.com/Thrimbda/dotfiles/pull/203) merged as `df26dce7f6b0652172cf5d604527f18d73cd76a5`.
- The exact production change is the single deletion `-    ./modules/oneex-portfolio-adapter.nix` from `hosts/acorn/default.nix` (`0` additions, `1` deletion).
- The mandated deployment succeeded from Axiom through build/realization, transfer, and Acorn activation; the active generation reports the merged revision, with no Nix build or evaluation on Acorn. See `test-report.md`.

## Verification

- Adapter and ACME units: `not-found`, `inactive`, `dead`.
- Adapter process: absent; TCP `8090` listener: absent.
- Active nginx vhost: hostname and `8090` absent; verified TLS rejects the hostname and the unauthenticated diagnostic returns the default `404`.
- Health: all nine checked unrelated services are active; no failed units exist.

## Retained Scope

The unread runtime age secret, its ciphertext/declaration, dormant adapter module, and package snapshot remain intentionally. No external/1Exchange account state, browser state, auth-mini state, credential, or secret was mutated.
