# Review RFC: Aliyun Acorn ECS Deployment Path

## Review 1

Verdict: FAIL

### Blocking Findings

- `docs/rfc.md:107-120` leaves first-boot SSH access as an open choice instead of a designed runbook path. This blocks implementation because the task acceptance requires SSH/first-boot validation, and the current `aliyun-acorn` image does not by itself define a committed authorized key or password path. The RFC must specify a non-secret runtime mechanism, such as cloud-init `UserData` generated from a local public key, and define how the validation command uses it.
- `docs/rfc.md:86-105` defines `ImportImage` parameters but does not specify how the operator preflights the Aliyun image-import role/permission and same-region OSS requirement. This blocks validation because an import failure would be ambiguous between account permission, role setup, bucket/object placement, and image incompatibility. The RFC must add a concrete preflight/check section and make role/bucket assumptions explicit.

### Non-blocking Suggestions

- Keep the durable `aliyun-ops` Terraform module as a follow-up, but make the validation-mode CLI path complete enough to execute after user confirmation.

## Review 2

Verdict: PASS

### Findings

- The blocking SSH-access gap is resolved. The RFC now requires runtime-generated cloud-init `UserData` from a local public key and validates SSH as `c1` without committed secrets.
- The image-import preflight gap is resolved. The RFC now requires same-region OSS object verification and a reviewed ECS image-import role before live `ImportImage`.
- Rollback is explicit for repository changes, validation ECS instance, custom image, staging OSS object/bucket, and temporary security rules.
- Verification is credible for both non-cloud repository work and optional live Aliyun execution.

### Residual Risks

- The actual Aliyun account may still lack the import role, bucket permission, or selected instance inventory; those are runtime blockers, not design blockers.
- Durable ECS ownership remains a follow-up in `aliyun-ops` if the validation instance should become long-lived.
