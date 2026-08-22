# Change Review: Acorn vnStat Traffic Accounting

## Verdict

PASS

## Findings

No blocking findings.

## Scope And Correctness

- `hosts/acorn/modules/platform.nix` contains the single approved declaration: `services.vnstat.enable = true`.
- The change does not alter firewall ports, routes, service endpoints, secrets, or application service configuration.
- The effective Acorn configuration evaluates with the service enabled, and the Axiom-built remote activation started `vnstat.service` successfully.

## Security Review

The security lens was applied because this is a production-host infrastructure change. No security trigger is introduced: `vnstat` adds no listener, credential, identity path, or external telemetry. It stores aggregate interface counters locally and uses the existing SSH administration boundary.

## Verification Coverage

The test report covers configuration evaluation, required Axiom-to-Acorn activation, daemon health, interface registration, and the existing public-service baseline. The absent first traffic sample is expected immediately after database creation and is documented as a warm-up limitation, not a failed check.
