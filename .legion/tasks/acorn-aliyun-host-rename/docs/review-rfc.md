# RFC Review: Acorn Aliyun Host Profile Rename

## Decision

PASS

## Findings

No blocking findings.

## Review Notes

- The RFC defines a single implementable decision: delete the old active `hosts/acorn` profile, move `hosts/aliyun-acorn` to `hosts/acorn`, and update active references without compatibility aliases.
- Verification is concrete enough for this repository: it covers the exposed host attr, runtime hostName, nested image flake, dry-run image build, diff hygiene, and stale active reference search.
- Rollback is clear because the task does not mutate remote resources, DNS, Terraform state, secrets, or live data.
- Scope is explicit about preserving historical `.legion/tasks/**` semantics, which prevents a broad and risky historical rewrite.

## Non-Blocking Suggestions

- During implementation, treat `.legion/wiki/**` as current-truth writeback only where needed; avoid bulk replacement of historical task summaries.
- If the scoped image dry-run is blocked by local Nix environment constraints, record the exact blocker in `test-report.md` and keep the host attr/hostName/image attr evaluations as minimum evidence.
