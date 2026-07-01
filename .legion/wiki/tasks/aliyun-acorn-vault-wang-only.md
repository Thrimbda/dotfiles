# Aliyun Acorn Vault Wang Only

Status: ready for PR

## Summary

Corrects `aliyun-acorn` Vaultwarden staging so this host deploys only `vault.0xc1.wang`. The previous `vault.0xc1.space` compatibility vhost on `aliyun-acorn` was removed.

## Current Shape

- `aliyun-acorn` nginx Vaultwarden vhost: `vault.0xc1.wang` only.
- `aliyun-acorn` self-signed staging cert domains include `vault.0xc1.wang` and do not include `vault.0xc1.space`.
- `services.vaultwarden.config.domain` is `https://vault.0xc1.wang`.
- `hosts/acorn` remains unchanged.

## Follow-Up

- Live deploy verification still needs console or restored SSH access to `aliyun-acorn`.
