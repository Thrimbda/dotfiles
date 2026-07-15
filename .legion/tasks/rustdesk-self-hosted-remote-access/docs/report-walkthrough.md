# Acorn RustDesk Server-Side Force Relay

> **Mode:** implementation
> **Production scope:** one line in `hosts/acorn/default.nix`, hbbs only
> **Verification:** PASS for diff, generated units, full Acorn build and pinned 1.1.14 source semantics
> **Change review:** PASS for PR entry; no blocking findings
> **Runtime relay:** NOT RUN / NOT PASS

## Why This Change

The operator-reported runtime sequence was:

1. Charlie's direct listener first advertised the wrong fake-IP.
2. After it was corrected to Charlie's LAN address, the controller still failed with `No route to host`.
3. The attempted client-side force-relay path did not actually select relay.

The user therefore approved RustDesk Server's hbbs-side force-relay mechanism.

## Production Change

The complete production diff is one hbbs setting:

```nix
systemd.services.rustdesk-signal.environment.ALWAYS_USE_RELAY = "Y";
```

The realized hbbs unit gains exactly `Environment="ALWAYS_USE_RELAY=Y"`. The hbbr unit is byte-identical to baseline. There is no Axiom or Charlie production change and no package, key, authentication, listener, port or firewall change.

## Existing Evidence

- Clean-baseline differential evaluation and generated-unit comparison prove the hbbs-only effective change; full Acorn toplevel build and closure checks: **PASS**.
- The pinned official RustDesk Server 1.1.14 source reads `ALWAYS_USE_RELAY=Y` in hbbs and marks the normal hole-punch response to select relay: **PASS** for source semantics.
- Independent change review: **PASS** for PR entry, including scope, regression and security lenses, with no blocking finding.

These are configuration, build and source-semantics results. No Acorn switch, service restart, fresh RustDesk session, relay-traffic observation, authentication test or bandwidth measurement was run for this candidate.

## Required After Merge

1. Complete required checks and switch Acorn only from a clean merged `origin/master` using a preserved non-RustDesk fallback.
2. Prove hbbs alone receives a new process identity and starts with `ALWAYS_USE_RELAY=Y`; prove hbbr remains active with the same process identity and unchanged listener exposure.
3. Close pre-switch sessions and establish a fresh Axiom↔Charlie session. Prove both sides actually pair through hbbr and observe relay traffic, with a direct-path negative control; do not reuse an old session as evidence.
4. Revalidate Charlie's ready-bound privileged-service and user-server PID/start identities. If either drifted, stop and do not finalize or reuse the pending ready state.
5. Repeat correct-password positive and wrong, old and cross-host negative authentication controls on the fresh relayed session.
6. Record representative hbbr load, throughput and Acorn ingress/egress cost, with an owner and containment threshold. Force relay makes Acorn/hbbr a data-plane and billing dependency for normal new sessions.

The upstream same-intranet branch remains a separate topology caveat; build/source PASS must not be presented as a topology-independent runtime guarantee.

Evidence: [`test-report.md`](./test-report.md), [`review-change.md`](./review-change.md).
