# RFC Review: FRP Agenix Deploy

Decision: PASS

## Findings

- No blocking rollback gap: disabling the two module toggles and removing firewall ports cleanly removes the new runtime path.
- No blocking verification gap: eval, dry-run build, frp config verification, render-script inspection, and age recipient/token consistency checks cover the important failure modes.
- No blocking scope ambiguity: the change explicitly does not remove existing autossh or expand into dashboards, TLS, metrics, or Cloudflare/Gatus integration.

## Notes

- Public `7000` and `2225` ports are intentional scope. `2225` avoids the existing autossh `2222`/`2223`/`2224` reservations. The main mitigation is high-entropy token auth and keeping the token out of store/logs.
- Runtime behavior still needs deployment-time service checks on the actual hosts after PR merge, because local eval cannot prove remote network reachability.
