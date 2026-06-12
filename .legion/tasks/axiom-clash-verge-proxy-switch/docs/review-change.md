# Review Change: Axiom Clash Verge Proxy Switch

## Result

PASS

## Blocking Findings

None.

## Scope Review

- The implementation adds a single standalone script at `bin/clash-switch.ts`.
- It does not modify Clash subscription YAML, proxy groups, Nix modules, system services, or firewall behavior.
- It records task-local Legion evidence under `.legion/tasks/axiom-clash-verge-proxy-switch/`.
- The CLI supports the accepted modes: `list`, explicit `switch <node>`, shorthand node argument, and no-argument interactive selector.
- Defaults match the confirmed axiom contract: controller `http://127.0.0.1:9090` and group `Nexitally`.

## Correctness Review

- `GET /proxies` response handling validates that `proxies` exists, the requested group exists, and `all[]` is a string list before listing or switching.
- `PUT /proxies/<group>` uses `encodeURIComponent` for the group path and sends `{ "name": target }`, matching the Clash/Mihomo API shape.
- Node selection prefers exact match, then case-insensitive exact match, then a unique substring match; ambiguous partial matches fail instead of silently picking a node.
- Non-TTY execution of the interactive mode fails with an actionable error rather than waiting for input.
- The executable shebang was validated with Node `v24.13.0`.

## Verification Review

Evidence in `docs/test-report.md` is sufficient for this change:

- Node version check confirms Node 24 is present.
- Executable `--help` confirms the shebang/runtime path and documented modes.
- Mock controller tests prove `list --json` and `switch Japan` behavior without touching the live axiom proxy selection.
- The `node --check` TypeScript caveat is documented and does not invalidate the actual Node 24 execution-path tests.

## Security Lens

Security lens applied because the change handles an optional controller API secret and sends local control-plane requests.

- No secret is added to repository files.
- `CLASH_API_SECRET` and `--secret` are only used to construct an `Authorization: Bearer ...` request header at runtime.
- The default controller is loopback-only, matching the existing `config/clash/config.yaml` controller binding.
- The script does not expose a listener, relax firewall policy, persist credentials, or alter auth/session behavior.
- Passing secrets via CLI can expose them to shell history or process listings; the environment variable path is available and safer. This is a usage caution, not a blocking repository security issue.

## Non-Blocking Suggestions

- If interactive behavior becomes important to automate later, add a small pseudo-TTY harness or move selector key parsing behind an injectable input function.
