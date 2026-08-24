# Change Review: Acorn Traffic Attribution

## Verdict

PASS

## Findings

No blocking findings.

## Scope And Correctness

- `hosts/acorn/modules/traffic-accounting.nix` is host-local and only imports into Acorn.
- It explicitly maintains existing IP accounting for the four candidate forwarding service cgroups, samples only aggregate counters, and uses the pre-existing loopback FRP API.
- The report handles missing FRP data and counter decreases without presenting a negative byte delta.
- The state layout uses one sample file per collection, so the tmpfiles 30-day age policy can actually expire historical data.

## Security Review

The security lens was applied because this changes a production host and adds retained observability state. The collector introduces no listener, firewall rule, external sink, credentials, request log, client identity, or payload capture. Samples are root-owned and contain only service/proxy names, statuses, connection counts, timestamps, and byte totals.

## Verification Coverage

The test report proves targeted Nix evaluation, Axiom-built remote activation, active production services, root-only sample permissions, and successful delta reporting across both service cgroups and current FRP proxies.
