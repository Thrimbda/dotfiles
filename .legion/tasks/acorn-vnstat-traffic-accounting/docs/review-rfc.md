# RFC Review: Acorn vnStat Traffic Accounting

## Verdict

PASS

The design is implementable with the pinned flake input: evaluating `nixosConfigurations.acorn.options.services.vnstat.enable.type.name` returns `bool`.

The proposed one-line service declaration has a defined activation path from Axiom, does not add a listener or firewall change, and can be rolled back with a Git revert or prior NixOS generation. Verification distinguishes configuration evaluation, remote activation, daemon health, and interface reporting.

## Reviewed Risks

- `vnstat` cannot reconstruct the current billing period or isolate a responsible service. The RFC states both as non-goals rather than implying otherwise.
- The service introduces persistent local counters but no secrets, payload capture, external telemetry, or exposed network surface.
- Acorn closure construction remains on Axiom as required.
