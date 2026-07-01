# Walkthrough

## Summary

This follow-up corrects the previous compatibility routing decision. `aliyun-acorn` now deploys Vaultwarden only at `vault.0xc1.wang`.

## Changed

- Removed `vault.0xc1.space` from staged self-signed TLS domain generation on `aliyun-acorn`.
- Removed `vault.0xc1.space` from `aliyun-acorn` nginx Vaultwarden proxy vhosts.
- Updated wiki current-truth so future work does not re-add `.space` as an Aliyun compatibility vhost.

## Unchanged

- `vault.0xc1.wang` remains the Vaultwarden public domain.
- ACME remains disabled during staging.
- Public `80` remains closed.
- `hosts/acorn` remains unchanged.
