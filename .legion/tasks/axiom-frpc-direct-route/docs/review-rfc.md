# RFC Review: Axiom FRPC Direct Route

Decision: PASS

## Blocking Findings

None.

## Notes

- The design is minimal and host-local.
- It preserves Clash Verge behavior for all other destinations.
- It does not weaken frp token auth, nginx Basic Auth, or `18080` public exposure boundaries.
- Runtime validation is clear and directly checks the route lookup that caused the failure.

## Residual Risk

If Clash/Meta changes policy-rule priority below `8500`, the direct route could stop winning; post-deploy route lookup validation should catch that.
