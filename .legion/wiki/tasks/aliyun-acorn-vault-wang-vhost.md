# Aliyun Acorn Vault Wang Vhost

Status: ready for PR

## Summary

Adds `vault.0xc1.wang` as the public Vaultwarden staging hostname on `aliyun-acorn` and changes Vaultwarden's configured public domain to `https://vault.0xc1.wang`. The existing `vault.0xc1.space` vhost remains as compatibility routing.

## Current Shape

- `vault.0xc1.wang` and `vault.0xc1.space` both proxy to local Vaultwarden on port `8000` and websocket hub on `3012`.
- `vault.0xc1.wang` is included in self-signed staged TLS cert generation.
- ACME remains disabled until DNS/cutover is ready.

## Follow-Up

- Console-side inspection is needed because live SSH currently rejects the expected public key even though the evaluated config contains it.
