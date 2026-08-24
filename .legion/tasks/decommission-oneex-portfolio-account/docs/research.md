# Research: Minimal 1Ex Portfolio Adapter Undeployment

## Conclusion

The complete production change is removal of this import from `hosts/acorn/default.nix`:
```diff
-    ./modules/oneex-portfolio-adapter.nix
```
`hosts/acorn/modules/oneex-portfolio-adapter.nix` owns the service, user/group, nginx vhost and port `8090` proxy, ACME contribution, and package evaluation; removing its import removes that active serving boundary.
`modules/agenix.nix:58-68` independently folds `hosts/acorn/secrets/secrets.nix` into `config.age.secrets`, so `age.secrets.oneex-portfolio-adapter-env` and its runtime secret intentionally remain.
Current Acorn evidence is `LoadState=loaded`, `ActiveState=inactive`, `SubState=dead`; until activation, reboot or manual start remains a residual risk.

## Boundaries

Non-goals are editing or deleting the dormant module, package, encrypted/runtime secret, or other production files; external account/browser/auth/DNS changes; masks or manual unit state; and any Acorn-local Nix evaluation or build.
Only Axiom may evaluate, build, and initiate deployment. Build, transfer, activation, or pre-deployment state drift is a hard stop with no Acorn fallback.
After activation, verify unit, process, TCP `8090`, and active-vhost absence plus failed-unit and unrelated-service health; secret presence is expected and must not be inspected.

## References

- Contract and runtime history: `../plan.md`, `../log.md`
- Production ownership: `hosts/acorn/default.nix`, `hosts/acorn/modules/oneex-portfolio-adapter.nix`, `modules/agenix.nix:58-68`
- Executed evidence: `test-report.md`; decisions: `rfc.md`, `review-rfc.md`, `review-change.md`
