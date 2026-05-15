# Review RFC: Gatus Status Page Blackbox Monitoring

> **Status**: PASS  
> **Reviewed**: 2026-05-15  
> **Source**: `.legion/tasks/gatus-status-page-blackbox-monitoring/docs/rfc.md`

## Findings

No blocking findings.

## Review Notes

- The RFC includes real alternatives and chooses the NixOS/acorn path for repo-fit reasons rather than convenience.
- The Prometheus gap was resolved before this review: `acorn` will explicitly enable Prometheus so `modules.services.gatus.prometheusScrape.enable` produces an actual scrape job in the first deployment.
- Rollback is configuration-only and executable: disable the wrapper/import, rebuild `acorn`, and leave or remove sqlite state as needed.
- Verification is credible for this repo: targeted Nix eval/build can validate option shape, nginx vhost, Gatus settings and Prometheus scrape config. DNS/ACME/runtime reachability are correctly classified as manual/post-deploy checks.
- Scope is bounded and avoids secrets, alert channels, incident workflow, private-only dependencies and production deployment.

## Suggestions

- During implementation, keep the Gatus wrapper small and use `extraSettings` rather than mirroring every upstream setting.
- Prefer public-safe endpoints and auth-aware status conditions; do not add private database/Redis/message queue checks to the public status page in this task.
- If current nixpkgs lacks an expected `services.gatus` option, keep the fallback within scope only if it remains a minimal systemd service wrapper; otherwise return to design.

## Decision

PASS. The design is implementable, verifiable and rollbackable within the task contract.
