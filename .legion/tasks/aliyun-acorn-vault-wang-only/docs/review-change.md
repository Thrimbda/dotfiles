# Review Change

## Verdict

Ready.

## Findings

No findings.

## Review Notes

- Change is scoped to `hosts/aliyun-acorn` and Legion evidence/wiki files.
- `hosts/acorn` is not modified.
- `aliyun-acorn` no longer evaluates a `vault.0xc1.space` nginx vhost or self-signed certificate generation entry.
- `vault.0xc1.wang` remains the configured Vaultwarden public domain.

## Residual Risk

- Live deploy verification still depends on restoring SSH or console access to `aliyun-acorn`; prior SSH attempts were rejected by the live server.
