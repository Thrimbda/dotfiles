# Test Report: Axiom Clash Verge Proxy Switch

## Summary

Result: PASS with one documented tooling caveat.

The implemented CLI was verified on local Node `v24.13.0`. The strongest checks are direct execution through the same Node 24 TypeScript stripping path the script will use, plus a local mock Clash/Mihomo controller that validates the REST calls for listing and switching nodes.

## Commands

### Node Runtime

Command:

```sh
node --version
```

Result: PASS

Evidence: printed `v24.13.0`.

### Executable Help Path

Command:

```sh
bin/clash-switch.ts --help
```

Result: PASS

Evidence: printed usage for `list`, `switch NODE`, shorthand `NODE`, no-argument interactive mode, `--controller`, `--group`, `--secret`, `--json`, and environment variable overrides.

### Mock Controller List/Switch

Command:

```sh
node --input-type=module --eval '<mock controller harness>'
```

The harness started a local HTTP server exposing:

- `GET /proxies` with a `Nexitally` group containing `Auto`, `Hong Kong 01`, and `Japan 01`.
- `PUT /proxies/Nexitally` recording the JSON body.

It then ran:

- `node --experimental-strip-types bin/clash-switch.ts list --json --controller=<mock>`
- `node --experimental-strip-types bin/clash-switch.ts switch Japan --controller=<mock>`

Result: PASS

Evidence:

- `list --json` returned `group: Nexitally`, `current: Hong Kong 01`, and all three mock nodes.
- `switch Japan` resolved the unique partial match to `Japan 01`.
- The recorded switch request was `PUT /proxies/Nexitally` with body `{ "name": "Japan 01" }`.

### Non-TTY Interactive Guard

Command:

```sh
node --input-type=module --eval '<non-tty mock controller harness>'
```

The harness ran the CLI with no command and no TTY against a mock controller.

Result: PASS

Evidence: command exited with code `1` and printed `Interactive selection requires a TTY; pass a node name instead`, proving non-interactive shells do not hang waiting for selector input.

## Tooling Caveat

Command:

```sh
node --experimental-strip-types --check bin/clash-switch.ts
```

Result: NOT USED as validation evidence.

Evidence: Node `--check` reported `Unexpected identifier 'Command'` at the first TypeScript `type` declaration, while actual Node 24 execution with `--experimental-strip-types` succeeded. This appears to be a `node --check` limitation for stripped TypeScript syntax rather than a runtime syntax failure. The direct execution and mock-controller runs are therefore the credible validation path for this dependency-free `.ts` script.

## Skipped

- Real axiom Clash Verge controller switching was not executed to avoid changing the user's live proxy selection during validation.
- Full interactive selector navigation was not automated because the current environment does not provide a stable TTY interaction harness; the non-TTY guard and direct code inspection cover the safety boundary, while manual use remains straightforward through the executable script.

## Why These Checks

- A full Nix evaluation would not prove this script's behavior because the change is a standalone `bin/` script and does not alter Nix modules.
- Mocking the Clash/Mihomo API gives deterministic proof that the script consumes `/proxies`, lists group entries, resolves a command-line node argument, and sends the expected `PUT /proxies/<group>` request.
- Direct executable help verifies the shebang and Node 24 TypeScript runtime path users will invoke.
