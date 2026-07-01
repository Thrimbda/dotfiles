# Aliyun Acorn Vault Wang Only

Status: implemented

## Goal

Correct the `aliyun-acorn` Vaultwarden staging scope so this host deploys only `vault.0xc1.wang` for Vaultwarden.

## Scope

- Remove `vault.0xc1.space` from `aliyun-acorn` staged TLS certificate generation.
- Remove `vault.0xc1.space` from `aliyun-acorn` nginx Vaultwarden proxy vhosts.
- Keep `services.vaultwarden.config.domain = "https://vault.0xc1.wang"`.
- Do not change the existing `hosts/acorn` Vaultwarden deployment.
- Preserve HTTPS-only staging on public `443`, keep public `80` closed, and keep ACME disabled for this staging phase.

## Acceptance

- Evaluated `aliyun-acorn` nginx vhosts contain `vault.0xc1.wang` and do not contain `vault.0xc1.space`.
- `hosts/aliyun-acorn` no longer references `vault.0xc1.space`.
- `aliyun-acorn` system build succeeds.
