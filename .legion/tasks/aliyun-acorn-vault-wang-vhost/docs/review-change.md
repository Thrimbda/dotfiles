# Review Change: Aliyun Acorn Vault Wang Vhost

## Decision

PASS

## Security Lens

Applied because this changes the public Vaultwarden hostname.

## Findings

No blocking findings.

## Confirmed

- `vault.0xc1.wang` is added as HTTPS-only staged nginx vhost.
- `vault.0xc1.wang` has the same proxy routes as `vault.0xc1.space`.
- Vaultwarden public domain now matches `https://vault.0xc1.wang`.
- ACME remains disabled and no ACME units are generated.
- Self-signed cert generation includes `vault.0xc1.wang`.
- Toplevel build passed.

## Residual Risk

- Live SSH access is currently blocked by server-side public key rejection; remote nginx/vaultwarden logs still require console-side inspection.
