# Auth Mini Empty Response Hotfix

## Goal

Fix the post-switch runtime failure where `https://auth.0xc1.wang` returns `NS_ERROR_NET_EMPTY_RESPONSE` after deploying the Acorn auth-mini/gateway change.

## Problem

The browser reaches `auth.0xc1.wang`, but the connection receives an empty response instead of the auth-mini web/API response. Because nginx terminates TLS and proxies `auth.0xc1.wang` to `127.0.0.1:7777`, the most likely causes are a failing `auth-mini.service`, a release-binary runtime dependency issue that was not exercised by the Nix build, or a loopback proxy/runtime mismatch.

## Scope

- Inspect live Acorn service/nginx logs and loopback behavior read-only to identify the root cause.
- If the root cause is repo-owned Nix config or packaging, implement the smallest fix.
- Keep the existing gateway design, protected vhosts, secrets, and Vaultwarden boundary unchanged unless directly required to restore `auth.0xc1.wang`.
- Record exact verification evidence for the fix.

## Non-Goals

- Do not redesign gateway auth policy, allowlists, or per-origin gateway topology.
- Do not rotate secrets.
- Do not configure live auth-mini admin/RP/SMTP metadata unless logs prove that is the direct cause of the empty response.
- Do not alter Vaultwarden.

## Acceptance Criteria

- The root cause of `auth.0xc1.wang` empty response is identified from live or local evidence.
- Repo-owned fix, if needed, builds in `.#nixosConfigurations.acorn.config.system.build.toplevel`.
- The fix includes a credible runtime-level check for the auth-mini binary/service behavior, not only Nix evaluation.
- `auth.0xc1.wang` is expected to return a valid HTTP response after switch; if live verification cannot be completed from this environment, exact post-deploy command is documented.
- Legion test report, review, walkthrough, and wiki writeback are updated.

## Assumptions

- SSH access to `acorn` or its public IP is available from this environment for read-only diagnostics.
- The screenshot corresponds to `auth.0xc1.wang` after PR #131 was switched on Acorn.
- The empty response is a regression from the deployed auth-mini package/service, not a client-side browser extension issue.

## Risks

- A release binary can pass Nix packaging but still fail on a minimal host if runtime files or HOME behavior differ.
- A live remote service may expose sensitive logs; diagnostics must avoid printing tokens or secret env values.
- A quick workaround that bypasses nginx or weakens auth would create a larger security regression.

## Recommended Direction

Treat this as a runtime hotfix. First verify `auth-mini.service` status, `journalctl`, nginx upstream errors, and direct loopback curl on Acorn. If the binary itself crashes, prefer switching `auth-mini` packaging from the upstream release tarball to a pinned source build or adding the missing runtime setup, whichever is smaller and evidence-backed. Keep nginx/gateway topology intact.

## Phases

1. Materialize this hotfix contract.
2. Run read-only live diagnostics and record findings.
3. Implement the minimal repo-owned fix if diagnostics show one is required.
4. Verify locally and, if possible, with a safe remote smoke check.
5. Review, walkthrough, wiki writeback, and PR lifecycle.
