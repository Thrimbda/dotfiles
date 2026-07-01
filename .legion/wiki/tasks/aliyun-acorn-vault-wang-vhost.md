# Aliyun Acorn Vault Wang Vhost

Status: superseded by `aliyun-acorn-vault-wang-only`

## Summary

Added `vault.0xc1.wang` as the public Vaultwarden staging hostname on `aliyun-acorn` and changed Vaultwarden's configured public domain to `https://vault.0xc1.wang`. Its temporary `vault.0xc1.space` compatibility routing was later removed by `aliyun-acorn-vault-wang-only`.

## Current Shape

- Superseded current shape: `aliyun-acorn` now deploys only `vault.0xc1.wang` for Vaultwarden.
- `vault.0xc1.wang` is included in self-signed staged TLS cert generation.
- ACME remains disabled until DNS/cutover is ready.

## Follow-Up

- Console-side inspection is needed because live SSH currently rejects the expected public key even though the evaluated config contains it.
